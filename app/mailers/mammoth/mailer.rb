module Mammoth
  class Mailer < ActionMailer::Base
    layout 'mammoth/email'
    default from: %{Newsmast <#{ENV['SMTP_FROM_ADDRESS']}>}

    def account_confirmation
      @user = params[:user]
      if @user.present?
        @subject = "Newsmast: Verify your email address"
        mail(to: @user.email, subject: @subject)
      end
    end

    def reset_password_confirmation
      @user = params[:user]
      if @user.present?
        @subject = "Newsmast: Reset your password"
        mail(to: @user.email, subject: @subject)
      end
    end

  end
end