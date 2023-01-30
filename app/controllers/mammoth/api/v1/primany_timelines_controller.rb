module Mammoth::Api::V1
  class PrimanyTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      # user_communities_ids = Mammoth::UserCommunity.where(user_id: current_user.id).pluck(:community_id).map(&:to_i)
      # statues_ids = Mammoth::CommunityStatus.where(community_id: user_communities_ids,is_primary: true).pluck(:status_id).map(&:to_i)
      # @statuses = Status.where(id: statues_ids).where.not(account_id: current_account.id)

      user_primary_community= Mammoth::UserCommunity.where(user_id: current_user.id, is_primary: true).last
      if user_primary_community.present?
        primary_community_statuses = Mammoth::CommunityStatus.where(community_id: user_primary_community.community_id).pluck(:status_id).map(&:to_i)
        @statuses = Status.where(id: primary_community_statuses).where.not(account_id: current_account.id)
      end

      render json: @statuses, each_serializer: Mammoth::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id)
    end

  end
end