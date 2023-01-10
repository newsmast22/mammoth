module NewsmastSsoClient
  class UserSessionsController < Api::BaseController

    skip_before_action :require_authenticated_user!
    
    def register_with_phone
      number_array = (1..9).to_a
      otp_code = (0...4).collect { number_array[Kernel.rand(number_array.length)] }.join

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
                    otp_code: otp_code,
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
        render json: {message: 'account confirmed', data: @user}
      else
        render json: {error: 'wrong otp'}
      end
    end

    private

    # def user_params
    #   # params.require(:user).permit(:phone, :username, :password, :password_cofirmation)
    # end

  end
end
