
module Mammoth::Api::V1

  class SearchController < Api::BaseController
    include Authorization

    RESULTS_LIMIT = 20

    before_action :require_user!
    before_action -> { authorize_if_got_token! :read, :'read:search' }
    before_action :validate_search_params!, only: [:create]

    def index
      @search = Search.new(search_results)
      render json: @search, serializer: Mammoth::SearchSerializer
    rescue Mastodon::SyntaxError
      unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      not_found
    end

    def search_my_communities
      @search = Search.new(search_results)
      render json: @search, serializer: Mammoth::SearchSerializer
    rescue Mastodon::SyntaxError
      unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      not_found
    end

    def get_all_community_status_timelines
      @user_search_setting = Mammoth::UserSearchSetting.find_by(user_id: current_user.id)

      @statuses = Mammoth::Status.where(reply: false).where.not(account_id: current_account.id)

      @statuses = @statuses.filter_with_words(params[:words].downcase) if params[:words].present?
      
      #begin::community filter
      create_default_user_search_setting() if @user_search_setting.nil?
      if @user_search_setting.selected_filters["communities_filter"]["selected_communities"].present?
        status_tag_ids = Mammoth::CommunityStatus.group(:community_id,:status_id).where(community_id: @user_search_setting.selected_filters["communities_filter"]["selected_communities"]).pluck(:status_id).map(&:to_i)
        @statuses = @statuses.merge(Mammoth::Status.filter_without_community_status_ids(status_tag_ids))
      end
      #end::community filter

      unless @statuses.empty?
        @statuses = @statuses.order(created_at: :desc).take(10)
        render json: @statuses,root: 'data', 
          each_serializer: Mammoth::StatusSerializer, adapter: :json
      else
        render json: {error: "Record not found"}
      end
    end

    def get_my_community_status_timelines
      @user_search_setting = Mammoth::UserTimelineSetting.find_by(user_id: current_user.id)

      user_community_ids = Mammoth::UserCommunity.where(user_id: current_account.user.id).pluck(:community_id).map(&:to_i)
      community_statuses_ids = Mammoth::CommunityStatus.where(community_id: user_community_ids).order(created_at: :desc).pluck(:status_id).map(&:to_i)
      @statuses = Mammoth::Status.where(reply: false,id: community_statuses_ids)

      @statuses = @statuses.filter_with_words(params[:words].downcase) if params[:words].present?
      
      #begin::community filter
      create_default_user_search_setting() if @user_search_setting.nil?
      if @user_search_setting.selected_filters["communities_filter"]["selected_communities"].present?
        status_tag_ids = Mammoth::CommunityStatus.group(:community_id,:status_id).where(community_id: @user_search_setting.selected_filters["communities_filter"]["selected_communities"]).pluck(:status_id).map(&:to_i)
        @statuses = @statuses.merge(Mammoth::Status.filter_without_community_status_ids(status_tag_ids))
      end
      #end::community filter

     unless @statuses.empty?
      @statuses = @statuses.order(created_at: :desc).take(10)
      render json: @statuses,root: 'data', 
      each_serializer: Mammoth::StatusSerializer, adapter: :json
      else
       render json: {error: "Record not found"}
     end
    end

    def create_user_search_setting
      Mammoth::UserSearchSetting.where(user_id: current_user.id).destroy_all
      Mammoth::UserSearchSetting.create!(
        user_id: current_user.id,
        selected_filters: params[:selected_filters]
      )
      render json: {message: 'Successfully created'}
    end

    def get_user_search_setting
      @user_search_setting = Mammoth::UserSearchSetting.find_by(user_id: current_user.id)
      if @user_search_setting.nil?
        render json:{data: []} 
       else
         render json: {data:@user_search_setting}
       end
    end

    private

    def validate_search_params!
      params.require(:q)

      return if user_signed_in?

      return render json: { error: 'Search queries pagination is not supported without authentication' }, status: 401 if params[:offset].present?

      render json: { error: 'Search queries that resolve remote resources are not supported without authentication' }, status: 401 if truthy_param?(:resolve)
    end

    def search_results
      SearchService.new.call(
        params[:q],
        current_account,
        limit_param(RESULTS_LIMIT),
        search_params.merge(resolve: truthy_param?(:resolve), exclude_unreviewed: truthy_param?(:exclude_unreviewed))
      )
    end

    def create_default_user_search_setting
      user_search_settings = Mammoth::UserSearchSetting.where(user_id: current_user.id)
      user_search_settings.destroy_all
      @user_search_setting = Mammoth::UserSearchSetting.create!(
        user_id: current_user.id,
        selected_filters: {
          communities_filter: {
            selected_communities: []
          }
        }
      )
    end

    def search_params
      params.permit(
        :type,
        :offset,
        :min_id,
        :max_id,
        :account_id,
        selected_filters: [
            communities_filter:[
              selected_communities: [],
            ]
        ]
      )
    end
  end

end