module Mammoth::Api::V1
  class PrimanyTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      user_primary_community= Mammoth::UserCommunity.where(user_id: current_user.id, is_primary: true).last
      if user_primary_community.present?
        primary_community_statuses = Mammoth::CommunityStatus.where(community_id: user_primary_community.community_id).order(created_at: :desc).take(10).pluck(:status_id).map(&:to_i)
        @statuses = Status.where(id: primary_community_statuses,reply: false).order(created_at: :desc)
      end
      render json: @statuses, each_serializer: Mammoth::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id)
    end

  end
end