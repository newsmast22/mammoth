module Mammoth::Api::V1
  class FollowingTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      statues_ids = Follow.where(account: current_account.id).pluck(:target_account_id).map(&:to_i)
      if statues_ids.any?
        @statuses = Status.where(account_id: statues_ids)
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