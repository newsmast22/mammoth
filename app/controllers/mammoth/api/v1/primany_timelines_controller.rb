module Mammoth::Api::V1
  class PrimanyTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      user_communities_ids = Mammoth::UserCommunity.where(user_id: current_user.id).pluck(:community_id).map(&:to_i)
      statues_ids = Mammoth::CommunityStatus.where(community_id: user_communities_ids).pluck(:status_id).map(&:to_i)
      @statuses = Status.where(id: statues_ids)

      render json: @statuses, each_serializer: REST::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id)
    end

  end
end