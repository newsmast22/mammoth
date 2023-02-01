module Mammoth::Api::V1
  class FollowingTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      followed_account_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
      if followed_account_ids.any?
        @statuses = Status.where(account_id: followed_account_ids,reply: false).order(created_at: :desc).take(10)
        if @statuses.any?
          render json: @statuses, each_serializer: Mammoth::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id)
        else
          render json: {error: "Record not found"}
        end
      else
        render json: {error: "Record not found"}
      end
    end

  end
end