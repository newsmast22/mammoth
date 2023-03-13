module Mammoth::Api::V1
  class PrimanyTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def index
      user_primary_community= Mammoth::UserCommunity.where(user_id: current_user.id, is_primary: true).last
      if user_primary_community.present?
        primary_community_statuses = Mammoth::CommunityStatus.where(community_id: user_primary_community.community_id).order(created_at: :desc).pluck(:status_id).map(&:to_i)

        #Begin::Filter
        fetch_primary_timeline_filter(primary_community_statuses)
        #End::Filter

        #@statuses = Status.where(id: primary_community_statuses,reply: false).order(created_at: :desc).take(10)
        #@statuses = []
        unless @statuses.empty?
        # @statuses = @statuses.page(params[:page]).per(20)

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

    # def fetch_filter_timeline_data(primary_community_statues_ids)
    #   @user_timeline_setting = Mammoth::UserTimelineSetting.find_by(user_id: current_user.id)
    #   unless @user_timeline_setting.nil? || @user_timeline_setting.selected_filters["is_filter_turn_on"] == false || @user_timeline_setting.selected_filters["location_filter"]["is_location_filter_turn_on"] == false
    #     if @user_timeline_setting.selected_filters["location_filter"]["selected_countries"].any?
    #       account_ids = Account.where(country: @user_timeline_setting.selected_filters["location_filter"]["selected_countries"]).pluck(:id).map(&:to_i)
    #       @statuses = Status.where(id: primary_community_statues_ids,reply: false,account_id: account_ids).order(created_at: :desc).take(10)
    #     else
    #       account_ids = Account.where(country: @user_timeline_setting.selected_filters["default_country"]).pluck(:id).map(&:to_i)
    #       @statuses = Status.where(id: primary_community_statues_ids,reply: false,account_id: account_ids).order(created_at: :desc).take(10)
    #     end
    #   else 
    #     @statuses = Status.where(id: primary_community_statues_ids,reply: false).order(created_at: :desc).take(10)
    #   end
    # end

    def fetch_primary_timeline_filter(primary_community_statues_ids)
      @user_timeline_setting = Mammoth::UserTimelineSetting.find_by(user_id: current_user.id)

      @statuses = Mammoth::Status.primary_timeline_filter(primary_community_statues_ids)

      return @statuses if @user_timeline_setting.nil? || @user_timeline_setting.selected_filters["is_filter_turn_on"] == false 

      #begin::country filter
      accounts = Mammoth::Account.primary_timeline_countries_filter(@user_timeline_setting.selected_filters["location_filter"]["selected_countries"]) if @user_timeline_setting.selected_filters["location_filter"]["selected_countries"].any?

      return @statuses = [] if accounts.blank?
      #end::country filter

      #begin:: source filter: contributor_role, voice, media
      accounts = Mammoth::Account.primary_timeline_contributor_role_filter(@user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"].present?

      accounts = Mammoth::Account.primary_timeline_voice_filter(@user_timeline_setting.selected_filters["source_filter"]["selected_voices"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_voices"].present?

      accounts = Mammoth::Account.primary_timeline_media_filter(@user_timeline_setting.selected_filters["source_filter"]["selected_media"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_media"].present?
      #end:: source filter: contributor_role, voice, media

      unless accounts.blank?
        account_ids = accounts.pluck(:id).map(&:to_i) 
        return @statuses.primary_timeline_accounts_filter(account_ids)
      else
        return @statuses = []
      end

    end

  end
end