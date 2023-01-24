module Mammoth::Api::V1
  class UserSessionsController < Api::BaseController

    before_action -> { doorkeeper_authorize! :write, :'write:accounts' }, only: [:create]
    before_action :check_enabled_registrations, only: [:create]
    before_action :generate_otp, except: [:verify_otp]
    skip_before_action :require_authenticated_user!
    
    def register_with_email
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
        invite_request_attributes: { text: user_params[:reason] }
      )
      Mammoth::Mailer.with(user: @user).account_confirmation.deliver_now

      render json: {data: @user}

    rescue ActiveRecord::RecordInvalid => e
      render json: ValidationErrorFormatter.new(e, 'account.username': :username, 'invite_request.text': :reason).as_json, status: :unprocessable_entity
    end

    def register_with_phone
      domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
      
      @account = Account.where(username: params[:username]).first_or_initialize(username: params[:username])
      @account.save(validate: false)

      @user = User.where(phone: params[:phone])
                  .first_or_initialize(
                    email: "#{params[:phone]}@#{domain}",
                    phone: params[:phone],
                    password: params[:password], 
                    password_confirmation: params[:password_cofirmation], 
                    role: UserRole.find('-99'), 
                    account: @account, 
                    agreement: true,
                    otp_code: @otp_code,
                    approved: true
                  )

      @user.save(validate: false)
      render json: {data: @user}
    end

    def verify_otp
      @user = User.find(params[:user_id])
      if @user.otp_code == params[:confirmed_otp_code]
        @user.confirmed_at = Time.now.utc
        @user.save(validate: false)

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
        render json: {error: 'wrong otp'}
      end
    end

    private

    def generate_otp
      number_array = (1..9).to_a
      @otp_code = (0...4).collect { number_array[Kernel.rand(number_array.length)] }.join
    end

    def user_params
      params.permit(:display_name, :username, :email, :password, :agreement, :locale, :reason)
    end

  end
end
