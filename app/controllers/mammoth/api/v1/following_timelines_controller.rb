module Mammoth::Api::V1
  class FollowingTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
    #after_action :insert_pagination_headers, unless: -> { @statuses.empty? }


    def index
      #Begin::Create UserTimeLineSetting
      userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id).last
      if userTimeLineSetting.nil?
        create_userTimelineSetting()
      elsif userTimeLineSetting.selected_filters.dig('location_filter').nil?
        create_userTimelineSetting()
      elsif userTimeLineSetting.selected_filters.dig('source_filter').nil?
        create_userTimelineSetting()
      elsif userTimeLineSetting.selected_filters.dig('communities_filter').nil?
        create_userTimelineSetting()
      end
      #End:Create UserTimeLineSetting

      followed_account_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
      followed_tag_ids = TagFollow.where(account_id: current_account.id).pluck(:tag_id).map(&:to_i)
      status_tag_ids = Mammoth::StatusTag.group(:tag_id,:status_id).where(tag_id:followed_tag_ids).pluck(:status_id).map(&:to_i)
      
      filtered_followed_statuses = Mammoth::Status.filter_with_status_ids(status_tag_ids,current_account.id).or( Mammoth::Status.filter_followed_accounts(followed_account_ids))


      unless filtered_followed_statuses.blank?
        #Begin::Filter
        fetch_following_filter_timeline(filtered_followed_statuses)
        #End::Filter
        unless @statuses.empty?
          puts "******************** filtered_followed_statuses ********************"
puts @statuses.inspect
          #@statuses = @statuses.page(params[:page]).per(20)
          # render json: @statuses.order(created_at: :desc).take(10) ,root: 'data', 
          # each_serializer: Mammoth::StatusSerializer, adapter: :json 
          render json: @statuses.order(created_at: :desc).take(10),root: 'data', 
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

    def fetch_following_filter_timeline(filtered_followed_statuses)
      @statuses = filtered_followed_statuses

      @user_timeline_setting = Mammoth::UserTimelineSetting.find_by(user_id: current_user.id)
      
      return @statuses if @user_timeline_setting.nil? || @user_timeline_setting.selected_filters["is_filter_turn_on"] == false 

      #begin::country filter
      is_country_filter = false
      
      # filter: country_filter_on && selected_country exists
      if @user_timeline_setting.selected_filters["location_filter"]["selected_countries"].any? && @user_timeline_setting.selected_filters["location_filter"]["is_location_filter_turn_on"] == true
        accounts = Mammoth::Account.filter_timeline_with_countries(@user_timeline_setting.selected_filters["location_filter"]["selected_countries"]) 
        is_country_filter = true
      end

      if is_country_filter == true && accounts.blank? == true
        return @statuses = []
      end
      #end::country filter
      
      #begin:: source filter: contributor_role, voice, media
      accounts = Mammoth::Account.all if accounts.blank?

      accounts = accounts.filter_timeline_with_contributor_role(@user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"].present?

      accounts = accounts.filter_timeline_with_voice(@user_timeline_setting.selected_filters["source_filter"]["selected_voices"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_voices"].present?

      accounts = accounts.filter_timeline_with_media(@user_timeline_setting.selected_filters["source_filter"]["selected_media"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_media"].present?
      #end:: source filter: contributor_role, voice, media

      @statuses = @statuses.filter_timeline_with_accounts(accounts.pluck(:id).map(&:to_i))

      #begin::community filter
      if @user_timeline_setting.selected_filters["communities_filter"]["selected_communities"].present?
        status_tag_ids = Mammoth::CommunityStatus.group(:community_id,:status_id).where(community_id: @user_timeline_setting.selected_filters["communities_filter"]["selected_communities"]).pluck(:status_id).map(&:to_i)
        @statuses = @statuses.merge(Mammoth::Status.filter_with_community_status_ids(status_tag_ids))
      end
      #end::community filter
    end

    def create_userTimelineSetting
      userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id)
      userTimeLineSetting.destroy_all
      Mammoth::UserTimelineSetting.create!(
        user_id: current_user.id,
        selected_filters: {
          default_country: current_user.account.country,
          location_filter: {
            selected_countries: [],
            is_location_filter_turn_on: false
          },
          is_filter_turn_on: true,
          source_filter: {
            selected_media: [],
            selected_voices: [],
            selected_contributor_role: []
          },
          communities_filter: {
            selected_communities: []
          }
        }
      )
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