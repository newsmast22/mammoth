module Mammoth::Api::V1
  class PrimanyTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      user_primary_community= Mammoth::UserCommunity.where(user_id: current_user.id, is_primary: true).last
      if user_primary_community.present?
        primary_community_statuses = Mammoth::CommunityStatus.where(community_id: user_primary_community.community_id).order(created_at: :desc).pluck(:status_id).map(&:to_i)
        @statuses = Status.where(id: primary_community_statuses,reply: false).order(created_at: :desc).take(10)
        unless @statuses.empty?
        # @statuses = @statuses.page(params[:page]).per(20)
          render json: @statuses,root: 'data', 
          each_serializer: Mammoth::StatusSerializer, adapter: :json
          # , 
          # meta: { pagination:
          #   { 
          #     total_pages: @statuses.total_pages,
          #     total_objects: @statuses.total_count,
          #     current_page: @statuses.current_page
          #   } }
        else
          render json: {
             error: "Record not found", 
             primary_community_name:user_primary_community.community.name,
             primary_community_slug: user_primary_community.community.slug 
            }
        end
      else
        render json: {data: [] }
      end
    end

  end
end