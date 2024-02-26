module Mammoth::Api::V1
	class NotificationTokensController < Api::BaseController
		before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_notification_token, only: %i[create]

    def index
      ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
        render json: @notification_token
      end
    end

    def create
      unless @notification_token.present?
        #begin::notification token insert
          Mammoth::NotificationToken.create(
          account_id: current_account.id,
          notification_token: params[:notification_token],
          platform_type: params[:platform_type]
        )
        #end::notification token insert
        render json: {message: "notification token saved"}
      else
        render json: {message: "notification token already exists"}
      end
      
      
    end

    def show
      ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
        render json: @notification_token
      end
    end

    def update 
    end

    def destroy
    end

    private

    def set_notification_token
			@notification_token = Mammoth::NotificationToken.find_by(notification_token: params[:notification_token],account_id: current_account.id)
		end

  end
end