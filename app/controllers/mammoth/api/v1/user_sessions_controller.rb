module Mammoth::Api::V1
  class UserSessionsController < Api::BaseController

    before_action -> { doorkeeper_authorize! :write, :'write:accounts' }, only: [:create]
    before_action :check_enabled_registrations, only: [:create]
    before_action :generate_otp, except: [:verify_otp, :verify_reset_password_otp, :update_password]
    before_action :find_by_email_phone, only: [:get_reset_password_otp, :verify_reset_password_otp, :reset_password]
    skip_before_action :require_authenticated_user!

    require 'aws-sdk-sns'
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
          otp_code: @otp_code,
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
          otp_code: @otp_code,
          password_confirmation: user_params[:password], 
          account_attributes: user_params.slice(:display_name, :username),
          invite_request_attributes: { text: user_params[:reason] },
          wait_list_id: nil,
          step: "dob",
          otp_code: @otp_code,
        )
      end
      
      Mammoth::Mailer.with(user: @user).account_confirmation.deliver_now

      #render json: {data: @user.as_json(except: [:otp_code])}

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

    private

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
      @user = User.find(params[:user_id])
      invited_code = Mammoth::WaitList.where(invitation_code: params[:invitation_code].downcase).last
      unless invited_code.nil? || invited_code.is_invitation_code_used == true
        if @user.otp_code == params[:confirmed_otp_code]
          @user.confirmed_at = Time.now.utc
          @user.otp_code = nil
          @user.step = "dob"
          @user.wait_list_id = invited_code.id
          @user.save(validate: false)

          #begin::invitation code update
          invited_code.update(is_invitation_code_used: true)
          #end::invitation code update

          #begin::notification token insert
          Mammoth::NotificationToken.create(
            account_id: @user.account_id,
            notification_token: params[:notification_token],
            platform_type: params[:platform_type]
          )
          #end::notification token insert

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
      else
        render json: {error: 'wrong invitation_code'}, status: 422
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
