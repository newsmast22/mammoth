module Mammoth::Api::V1
  class UserSessionsController < Api::BaseController

    before_action -> { doorkeeper_authorize! :write, :'write:accounts' }, except: [:connect_with_instance]
    before_action :check_enabled_registrations, only: [:create]
    before_action :generate_otp, except: [:verify_otp, :verify_reset_password_otp, :update_password]
    before_action :find_by_email_phone, only: [:get_reset_password_otp, :verify_reset_password_otp, :reset_password]
    skip_before_action :require_authenticated_user!

    require 'aws-sdk-sns'
    require 'net/http'
    #require 'open-uri'

    def register_with_email
      @user = User.find_by(email: user_params[:email])
      if @user.nil?
        @user = User.create!( 
          created_by_application: doorkeeper_token.application, 
          sign_up_ip: request.remote_ip, 
          email: user_params[:email], 
          password: user_params[:password], 
          agreement: user_params[:agreement],
          locale: user_params[:locale],
          password_confirmation: user_params[:password], 
          account_attributes: user_params.slice(:display_name, :username),
          invite_request_attributes: { text: user_params[:reason] },
          wait_list_id: nil,
          step: "dob",
          otp_code: @otp_code,
        )
      elsif !@user.confirmed_at.present?
        @user.update!(otp_code: @otp_code)
        @user.account.update!(username: user_params[:username])
      else
        @user = User.create!( 
          created_by_application: doorkeeper_token.application, 
          sign_up_ip: request.remote_ip, 
          email: user_params[:email], 
          password: user_params[:password], 
          agreement: user_params[:agreement],
          locale: user_params[:locale],
          password_confirmation: user_params[:password], 
          account_attributes: user_params.slice(:display_name, :username),
          invite_request_attributes: { text: user_params[:reason] },
          wait_list_id: nil,
          step: "dob",
          otp_code: @otp_code,
        )
      end
      
      Mammoth::Mailer.with(user: @user).account_confirmation.deliver_now

      render json: {data: @user}

    rescue ActiveRecord::RecordInvalid => e
      render json: ValidationErrorFormatter.new(e, 'account.username': :username, 'invite_request.text': :reason).as_json, status: :unprocessable_entity
    end

    def register_with_phone

      domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
      @user = User.find_by(phone: user_params[:phone])
      if @user.nil?
        @user = User.create!(
          created_by_application: doorkeeper_token.application, 
          sign_up_ip: request.remote_ip, 
          email: "#{user_params[:phone]}@#{domain}", 
          password: user_params[:password], 
          agreement: user_params[:agreement],
          locale: user_params[:locale],
          otp_code: @otp_code,
          phone: user_params[:phone],
          password_confirmation: user_params[:password], 
          account_attributes: user_params.slice(:display_name, :username),
          invite_request_attributes: { text: user_params[:reason] },
          wait_list_id: nil,
          step: "dob",
        )
        @user.save(validate: false)
        set_sns_publich(user_params[:phone])
      elsif !@user.confirmed_at.present?
        @user.update!(otp_code: @otp_code)
        @user.account.update!(username: user_params[:username])
        set_sns_publich(user_params[:phone])
      else
        @user = User.create!(
          created_by_application: doorkeeper_token.application, 
          sign_up_ip: request.remote_ip, 
          email: "#{user_params[:phone]}@#{domain}", 
          password: user_params[:password], 
          agreement: user_params[:agreement],
          locale: user_params[:locale],
          otp_code: @otp_code,
          phone: user_params[:phone],
          password_confirmation: user_params[:password], 
          account_attributes: user_params.slice(:display_name, :username),
          invite_request_attributes: { text: user_params[:reason] },
          wait_list_id: nil,
          step: "dob",
        )
      end

      render json: {data: @user}
      
    rescue ActiveRecord::RecordInvalid => e
        render json: ValidationErrorFormatter.new(e, 'account.username': :username, 'invite_request.text': :reason).as_json, status: :unprocessable_entity
    end

    def get_reset_password_otp
      @user.update(otp_code: @otp_code)
      if params[:email].present?
        Mammoth::Mailer.with(user: @user).reset_password_confirmation.deliver_now
      else
        phone_no = "+"+params[:phone]
        set_sns_publich(phone_no)
      end
      render json: {data: @user}
    end

    def verify_reset_password_otp
      if @user.otp_code == params[:confirmed_otp_code]
        @user.update(otp_code: nil)
        render json: {message: 'Reset password OTP verification successed.'}, status: 200
      else
        render json: {error: 'Reset password OTP verification failed.'}, status: 422
      end
    end

    def reset_password
      if params[:password].present?
        @user.update(password: params[:password])
        @app = doorkeeper_token.application
        @access_token = Doorkeeper::AccessToken.create!(
          application: @app,
          resource_owner_id: @user.id,
          scopes: @app.scopes,
          expires_in: Doorkeeper.configuration.access_token_expires_in,
          use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
        )
        response = Doorkeeper::OAuth::TokenResponse.new(@access_token)
        render json: {message: 'password updating successed', access_token: JSON.parse(Oj.dump(response.body["access_token"]))}
      end
    end

    def verify_otp

      if params[:user_id].present? 
        verify_otp_code_for_signup()
      end

      unless params[:user_id].present?
        verify_otp_code_for_update()
      end
    end

    def connect_with_instance
      if params[:instance].present? && params[:code].present?
        base_url = request.base_url
        return render json: {
          instance: params[:instance],
          code: params[:code],
          redirect_uri: "#{base_url}/api/v1/connect_with_instance?instance=mastodon.social",
        }
      end
    end

    def create_user_object 
      if params[:instance].present? && params[:client_id].present? && params[:client_secret].present?
        base_url = request.base_url

        
        uri = URI("https://#{params[:instance]}/oauth/token")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.path)
        request.set_form_data(
          'client_id' => params[:client_id],
          'client_secret' => params[:client_secret],
          'code' => params[:code],
          'grant_type' => 'authorization_code',
          'redirect_uri' => "#{base_url}/api/v1/connect_with_instance?instance=mastodon.social"
        )

        response = http.request(request)
        token_data = JSON.parse(response.body)

        # The token_data should contain an access token that you can use to make authenticated API requests.
        access_token = token_data['access_token']

        access_token = '1MdZet9N41INxVQP26fUikz8cFrtjnpBK4RbXQ7gip8'

        puts "------------------------------------ accessTOken: #{access_token}"

        # Fetch user object by access_token
        api_uri = URI("https://#{params[:instance]}/api/v1/accounts/verify_credentials")
        http = Net::HTTP.new(api_uri.host, api_uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(api_uri.path)
        request['Authorization'] = "Bearer #{access_token}"
        response = http.request(request)
        user_data = JSON.parse(response.body)

        @account = Account.find_by(domain: params[:instance], username: user_data["username"])
        @user = User.find_by(account_id: @account.try(:id).nil? ? 0 : @account.id)

        if @user.nil?
          @user = User.new()
          @user.created_by_application= doorkeeper_token.application
          @user.sign_up_ip= " "
          @user.email= "" 
          @user.password= nil 
          @user.agreement= true
          @user.locale= "en"
          @user.password_confirmation= nil 
          if @account.nil?
            @user.account_attributes = {
              display_name: user_data["display_name"],
              username: user_data["username"],
              domain: params[:instance],
              note: user_data["note"],
              uri: user_data["uri"],
              url: user_data["url"],
              fields: user_data["fields"],
              discoverable: user_data["discoverable"],
              hide_collections: user_data["hide_collections"],
              #avatar: image_exitst(user_data["avatar"]) === true ? File.open(set_image(user_data["avatar"], user_data["id"], "avatar")) : nil,
              #header: image_exitst(user_data["header"]) === true ? File.open(set_image(user_data["header"], user_data["id"], "header")) : nil,
            }
          else 
            @user.account_id = @account.id
          end
          @user.invite_request_attributes = { text:user_data["reason"] }
          @user.wait_list_id = nil
          @user.step = "dob"
          @user.otp_code = nil
          @user.confirmed_at = Time.now.utc
          @user.save(validate: false)

          # Delete images (avatar/header) in tmp folders
          #File.delete("#{user_data["id"]}#{user_data["avatar"]}.png") if image_exitst(user_data["avatar"]) === true
          #File.delete("#{user_data["id"]}#{user_data["header"]}.png") if image_exitst(user_data["header"]) === true

        end

        @app = doorkeeper_token.application
        @token = Doorkeeper::AccessToken.where(token: access_token).last
        unless @token.present?
          @token = Doorkeeper::AccessToken.new(
            token: access_token,
            application: @app,
            resource_owner_id: @user.id,
            scopes: @app.scopes,
            expires_in: Doorkeeper.configuration.access_token_expires_in,
            use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
          )
          @token.save(validate: false)
        end
        render json: {
          access_token: access_token,
          token_type: 'Bearer',
          scope: @app.scopes,
          created_at: @user.created_at,
          role: 'end-user',
          community_slug: "",
          is_active: true,
          is_account_setup_finished: @user.is_account_setup_finished,
          step: @user.step,
          user_id: @user.id
        }

      end
    end

    private

    def set_image(image_url, id, photo_type)
      url = image_url
      file = open(url)
      # Save the file locally, e.g., in the /tmp directory
      local_photo_path = Rails.root.join('tmp', "#{id}#{photo_type}.png")
      File.open(local_photo_path, 'wb') do |f|
        f.write(file.read)
      end
      return local_photo_path
    end

    def image_exitst(image_url)
      return false if image_url.include?("missing.png")
      true
    end

    def verify_otp_code_for_update
      @user = User.where(otp_code: params[:confirmed_otp_code]).last
      if @user.present?
        is_email_flag = false
        if @user.otp_code == params[:confirmed_otp_code]
          @user.otp_code = nil

          unless @user.unconfirmed_email.nil?
            @user.email = @user.unconfirmed_email
            @user.skip_reconfirmation!
            is_email_flag = true
          end
          @user.save(validate: false)

          if is_email_flag
            @user.update_attribute(:unconfirmed_email, nil)
          end

          render json: {message: 'update successed'}
        else
          render json: {error: 'wrong otp'}
        end
      else
        render json: {error: 'wrong otp'}, status: 422
      end   
    end

    def verify_otp_code_for_signup
      @user = User.find(params[:user_id].to_i)
      invitation_code = params[:invitation_code].present? ? params[:invitation_code].downcase : ""
      invited_code = Mammoth::WaitList.where(invitation_code: invitation_code).last
      if @user.otp_code == params[:confirmed_otp_code]
        @user.confirmed_at = Time.now.utc
        @user.otp_code = nil
        @user.step = "dob"
        @user.wait_list_id = invited_code.id unless invited_code.nil? || invited_code.is_invitation_code_used == true
        @user.save(validate: false)

        #begin::invitation code update
        invited_code.update(is_invitation_code_used: true) unless invited_code.nil? || invited_code.is_invitation_code_used == true
        #end::invitation code update

        @app = doorkeeper_token.application
        @access_token = Doorkeeper::AccessToken.create!(
          application: @app,
          resource_owner_id: @user.id,
          scopes: @app.scopes,
          expires_in: Doorkeeper.configuration.access_token_expires_in,
          use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
        )
        response = Doorkeeper::OAuth::TokenResponse.new(@access_token)
        render json: {message: 'account confirmed', access_token: JSON.parse(Oj.dump(response.body["access_token"]))}
      else
        render json: {error: 'wrong otp'}, status: 422
      end
    end

    def find_by_email_phone
      if params[:email].present?
        @user = User.find_by(email: params[:email])
      else
        phone_no = ""
        if (params[:phone].include?("+"))
          phone_no = params[:phone]
        else
          phone_no = "+"+params[:phone]
        end
        @user = User.find_by(phone: phone_no)
      end
      raise ActiveRecord::RecordNotFound unless @user
    end

    def generate_otp
      @otp_code = (1000..9999).to_a.sample
    end

    def set_sns_publich(phone)
      @client = Aws::SNS::Client.new(
        region: ENV['SMS_REGION'],
        access_key_id: ENV['SMS_ACCESS_KEY_ID'],
        secret_access_key: ENV['SMS_SECRET_ACCESS_KEY']
      )
      @client.set_sms_attributes({
        attributes: { # required
          "DefaultSenderID" => "Newsmast",
          "DefaultSMSType" => "Transactional"
        },
      })
      @client.publish({
        phone_number: phone,
        message: "#{@otp_code} is your Newsmast verification code.", # required
        message_attributes: {
          "String" => {
            data_type: "String", # required
            string_value: "String",
          },
        }
      })
    end

    def user_params
      params.permit(:display_name, :username, :email, :password, :agreement, :locale, :reason,:phone,:invitation_code)
    end

  end
end
