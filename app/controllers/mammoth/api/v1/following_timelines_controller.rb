module Mammoth::Api::V1
  class FollowingTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
    #after_action :insert_pagination_headers, unless: -> { @statuses.empty? }


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


    # begin::mastodon paginations
    # def index
    #   followed_account_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
    #   if followed_account_ids.any?
    #     @statuses = load_statuses
    #     if @statuses.any?
    #       render json: @statuses ,root: 'data', 
    #       each_serializer: Mammoth::StatusSerializer, adapter: :json
    #     else
    #       render json: {error: "Record not found"}
    #     end
    #   else
    #     render json: {error: "Record not found"}
    #   end
    # end

    # def load_statuses
    #   cached_following_statuses_page
    # end
  
    # def cached_following_statuses_page
    #   cache_collection(following_statuses, Status)
    # end
  
    # def following_statuses
    #   following_feed.get(
    #     limit_param(DEFAULT_STATUSES_LIMIT),
    #     params[:max_id],
    #     params[:since_id],
    #     params[:min_id],
    #   )
    # end
  
    # def following_feed
    #   Mammoth::FollowingFeed.new(
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
    #   api_v1_following_timelines_url	 pagination_params(max_id: pagination_max_id)
    # end
  
    # def prev_path
    #   api_v1_following_timelines_url pagination_params(min_id: pagination_since_id)
    # end
  
    # def pagination_max_id
    #   @statuses.last.id
    # end
  
    # def pagination_since_id
    #   @statuses.first.id
    # end
    # end::mastodon paginations
  end
end