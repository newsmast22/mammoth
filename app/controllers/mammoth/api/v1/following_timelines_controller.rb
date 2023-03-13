module Mammoth::Api::V1
  class FollowingTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
    #after_action :insert_pagination_headers, unless: -> { @statuses.empty? }


    def index
      followed_account_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
      if followed_account_ids.any?
        #Begin::Filter
        fetch_filter_timeline_data(followed_account_ids)
        #fetch_following_filter_timeline(followed_account_ids)
        #End::Filter
        #@statuses = []
        unless @statuses.empty?
          #@statuses = @statuses.page(params[:page]).per(20)
          # render json: @statuses.order(created_at: :desc).take(10) ,root: 'data', 
          # each_serializer: Mammoth::StatusSerializer, adapter: :json 
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
          render json: {error: "Record not found"}
        end
      else
        render json: {data: []}
      end
    end

    private

    def fetch_filter_timeline_data(followed_account_ids)
      followed_tag_ids = TagFollow.where(account_id: current_account.id).pluck(:tag_id).map(&:to_i)
      @user_timeline_setting = Mammoth::UserTimelineSetting.find_by(user_id: current_user.id)
      unless @user_timeline_setting.nil? || @user_timeline_setting.selected_filters["is_filter_turn_on"] == false || @user_timeline_setting.selected_filters["location_filter"]["is_location_filter_turn_on"] == false
        if @user_timeline_setting.selected_filters["location_filter"]["selected_countries"].any?
          account_ids = Account.where(country: @user_timeline_setting.selected_filters["location_filter"]["selected_countries"]).pluck(:id).map(&:to_i)
          filtered_ids = followed_account_ids & account_ids
          if followed_tag_ids.any?
            user_followed_statuses = Status.where(account_id: filtered_ids,reply: false).order(created_at: :desc).to_sql
            tag_followed_statuses = Status.where(reply: false).order(created_at: :desc).to_sql
            combined_statuses  = Status.from("(((#{user_followed_statuses} ) UNION ( #{tag_followed_statuses} ))) statuses")
            .order(created_at: :desc).take(10)
            @statuses = Status.where(account_id: filtered_ids,reply: false).order(created_at: :desc).take(10) || combined_statuses
          else
            @statuses = Status.where(account_id: filtered_ids,reply: false).order(created_at: :desc).take(10)
          end
        end
      else 
        if followed_tag_ids.any?
          user_followed_statuses = Status.where(account_id: followed_account_ids,reply: false).order(created_at: :desc).to_sql
          tag_followed_statuses = Status.where(reply: false).order(created_at: :desc).to_sql
          combined_statuses = Status.from("(((#{user_followed_statuses} ) UNION ( #{tag_followed_statuses} ))) statuses")
          .order(created_at: :desc).take(10)
          @statuses  = Status.where(account_id: followed_account_ids,reply: false).order(created_at: :desc).take(10) || combined_statuses
        else
          @statuses = Status.where(account_id: followed_account_ids,reply: false).order(created_at: :desc).take(10) 
        end
      end
    end

    def fetch_following_filter_timeline(followed_account_ids)
      @user_timeline_setting = Mammoth::UserTimelineSetting.find_by(user_id: current_user.id)
      @statuses = Mammoth::Status.following_timeline_accounts_filter(followed_account_ids)
      return @statuses if @user_timeline_setting.nil? || @user_timeline_setting.selected_filters["is_filter_turn_on"] == false 

      followed_tag_ids = TagFollow.where(account_id: current_account.id).pluck(:tag_id).map(&:to_i)
      if followed_tag_ids.any?
        status_tag_ids = Mammoth::StatusTag.group(:status_id).where(tag_id:followed_tag_ids).pluck(:status_id).map(&:to_i)
        @statuses = @statuses.or(Mammoth::Status.following_filter_with_followed_tags(status_tag_ids))
      end

      #begin::country filter
      accounts = Mammoth::Account.primary_timeline_countries_filter(@user_timeline_setting.selected_filters["location_filter"]["selected_countries"]) if @user_timeline_setting.selected_filters["location_filter"]["selected_countries"].any?

      return @statuses = [] if accounts.blank?
      #end::country filter

      #begin:: source: contributor_role, voice, media
      accounts = Mammoth::Account.primary_timeline_contributor_role_filter(@user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"].present?

      accounts = Mammoth::Account.primary_timeline_voice_filter(@user_timeline_setting.selected_filters["source_filter"]["selected_voices"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_voices"].present?

      accounts = Mammoth::Account.primary_timeline_media_filter(@user_timeline_setting.selected_filters["source_filter"]["selected_media"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_media"].present?
      #end:: source: contributor_role, voice, media

      unless accounts.blank?
        account_ids = accounts.pluck(:id).map(&:to_i) 
        return @statuses.primary_timeline_accounts_filter(account_ids)
      else
        return @statuses = []
      end


      
      
      # unless @user_timeline_setting.nil? || @user_timeline_setting.selected_filters["is_filter_turn_on"] == false || @user_timeline_setting.selected_filters["location_filter"]["is_location_filter_turn_on"] == false
      #   if @user_timeline_setting.selected_filters["location_filter"]["selected_countries"].any?
      #     account_ids = Account.where(country: @user_timeline_setting.selected_filters["location_filter"]["selected_countries"]).pluck(:id).map(&:to_i)
      #     filtered_ids = followed_account_ids & account_ids
      #     if followed_tag_ids.any?
      #       user_followed_statuses = Status.where(account_id: filtered_ids,reply: false).order(created_at: :desc).to_sql
      #       tag_followed_statuses = Status.where(reply: false).order(created_at: :desc).to_sql
      #       combined_statuses  = Status.from("(((#{user_followed_statuses} ) UNION ( #{tag_followed_statuses} ))) statuses")
      #       .order(created_at: :desc).take(10)
      #       @statuses = Status.where(account_id: filtered_ids,reply: false).order(created_at: :desc).take(10) || combined_statuses
      #     else
      #       @statuses = Status.where(account_id: filtered_ids,reply: false).order(created_at: :desc).take(10)
      #     end
      #   end
      # else 
      #   if followed_tag_ids.any?
      #     user_followed_statuses = Status.where(account_id: followed_account_ids,reply: false).order(created_at: :desc).to_sql
      #     tag_followed_statuses = Status.where(reply: false).order(created_at: :desc).to_sql
      #     combined_statuses = Status.from("(((#{user_followed_statuses} ) UNION ( #{tag_followed_statuses} ))) statuses")
      #     .order(created_at: :desc).take(10)
      #     @statuses  = Status.where(account_id: followed_account_ids,reply: false).order(created_at: :desc).take(10) || combined_statuses
      #   else
      #     @statuses = Status.where(account_id: followed_account_ids,reply: false).order(created_at: :desc).take(10) 
      #   end
      # end
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