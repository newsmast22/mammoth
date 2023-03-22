module Mammoth::Api::V1
  class PrimanyTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

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

      user_primary_community= Mammoth::UserCommunity.where(user_id: current_user.id, is_primary: true).last
      if user_primary_community.present?
        primary_community_statuses = Mammoth::CommunityStatus.where(community_id: user_primary_community.community_id).order(created_at: :desc).pluck(:status_id).map(&:to_i)

        #Begin::Filter
        #fetch_filter_timeline_data(primary_community_statuses)
        fetch_primary_timeline_filter(primary_community_statuses)
        #End::Filter

        unless @statuses.empty?
        # @statuses = @statuses.page(params[:page]).per(20)

          render json: @statuses.order(created_at: :desc).take(10),root: 'data', 
          each_serializer: Mammoth::StatusSerializer, adapter: :json

          #render json: @statuses.order(created_at: :desc).take(1)

          # render json: @statuses,root: 'data', 
          # each_serializer: Mammoth::StatusSerializer, adapter: :json
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

    private

    def fetch_primary_timeline_filter(primary_community_statues_ids)
      return @statuses = [] unless primary_community_statues_ids.any?

      @user_timeline_setting = Mammoth::UserTimelineSetting.find_by(user_id: current_user.id)
			account_followed_ids = Follow.where(account_id: current_account).pluck(:target_account_id).map(&:to_i)
      account_followed_ids.push(current_account.id)

      @statuses = Mammoth::Status.filter_with_community_status_ids(primary_community_statues_ids)
      @statuses = @statuses.filter_is_only_for_followers(account_followed_ids)


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

      #begin::source filter: contributor_role, voice, media
      accounts = Mammoth::Account.all if accounts.blank?

      accounts = accounts.filter_timeline_with_contributor_role(@user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"].present?

      accounts = accounts.filter_timeline_with_voice(@user_timeline_setting.selected_filters["source_filter"]["selected_voices"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_voices"].present?

      accounts = accounts.filter_timeline_with_media(@user_timeline_setting.selected_filters["source_filter"]["selected_media"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_media"].present?

      #end::source filter: contributor_role, voice, media

      @statuses = @statuses.filter_timeline_with_accounts(accounts.pluck(:id).map(&:to_i))

      #begin::community filter
      if @user_timeline_setting.selected_filters["communities_filter"]["selected_communities"].present?
        status_tag_ids = Mammoth::CommunityStatus.group(:community_id,:status_id).where(community_id: @user_timeline_setting.selected_filters["communities_filter"]["selected_communities"]).pluck(:status_id).map(&:to_i)
        @statuses = @statuses.merge(Mammoth::Status.filter_with_status_ids(status_tag_ids))
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

  end
end