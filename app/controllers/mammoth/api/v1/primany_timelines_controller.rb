module Mammoth::Api::V1
  class PrimanyTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      user_primary_community= Mammoth::UserCommunity.where(user_id: current_user.id, is_primary: true).last
      if user_primary_community.present?
        primary_community_statuses = Mammoth::CommunityStatus.where(community_id: user_primary_community.community_id).order(created_at: :desc).pluck(:status_id).map(&:to_i)
        @statuses = Status.where(id: primary_community_statuses,reply: false).order(created_at: :desc)
      end
      @statuses = @statuses.page(params[:page]).per(10)
      render json: @statuses,root: 'data', 
      each_serializer: Mammoth::StatusSerializer, adapter: :json, 
      meta: { pagination:
        { 
          total_pages: @statuses.total_pages,
          total_objects: @statuses.total_count,
          current_page: @statuses.current_page
        } }
    end

    # def load_statuses
    #   cached_public_statuses_page
    # end
  
    # def cached_public_statuses_page
    #   user_primary_community= Mammoth::UserCommunity.where(user_id: current_user.id, is_primary: true).last
    #   if user_primary_community.present?
    #     primary_community_statuses = Mammoth::CommunityStatus.where(community_id: user_primary_community.community_id).order(created_at: :desc).take(10).pluck(:status_id).map(&:to_i)
    #     @statuses = Status.where(id: primary_community_statuses,reply: false).order(created_at: :desc)
    #   end
    #   cache_collection(public_statuses, Status)
    # end
  
    # def public_statuses
    #   public_feed.get(
    #     limit_param(DEFAULT_STATUSES_LIMIT),
    #     params[:max_id],
    #     params[:since_id],
    #     params[:min_id]
    #   )
    # end
  
    # def public_feed
    #   PublicFeed.new(
    #     current_account,
    #     local: truthy_param?(:local),
    #     remote: truthy_param?(:remote),
    #     only_media: truthy_param?(:only_media)
    #   )
    # end

    # def insert_pagination_headers
    #   set_pagination_headers(next_path, prev_path)
    # end
  
    # def pagination_params(core_params)
    #   params.slice(:local, :remote, :limit, :only_media).permit(:local, :remote, :limit, :only_media).merge(core_params)
    # end
  
    # def next_path
    #   api_v1_timelines_public_url pagination_params(max_id: pagination_max_id)
    # end
  
    # def prev_path
    #   api_v1_timelines_public_url pagination_params(min_id: pagination_since_id)
    # end
  
    # def pagination_max_id
    #   @statuses.last.id
    # end
  
    # def pagination_since_id
    #   @statuses.first.id
    # end
  end
end