module Mammoth::Api::V1
  class FollowingTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      followed_account_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
      if followed_account_ids.any?
        @statuses = Status.where(account_id: followed_account_ids,reply: false).order(created_at: :desc)
        if @statuses.any?
          @statuses = @statuses.page(params[:page]).per(10)
          render json: @statuses ,root: 'data', 
          each_serializer: Mammoth::StatusSerializer, adapter: :json, 
          meta: { pagination:
            { 
              total_pages: @statuses.total_pages,
              total_objects: @statuses.total_count,
              current_page: @statuses.current_page
            } }
        else
          render json: {error: "Record not found"}
        end
      else
        render json: {error: "Record not found"}
      end
    end

  end
end