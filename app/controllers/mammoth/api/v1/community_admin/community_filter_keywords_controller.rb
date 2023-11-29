module Mammoth::Api::V1::CommunityAdmin
  class CommunityFilterKeywordsController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_community_filter_keyword, only: %i[show update destroy]
    before_action :set_community_id, only: %i[create index]

    def index
      ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
        # Assign limit = 5 as 6 if limit is nil
        # Limit always plus one 
        # Addition plus one to get has_more_object

        limit = params[:limit].present? ? params[:limit].to_i + 1 : 6
        offset = params[:offset].present? ? params[:offset] : 0

        default_limit = limit - 1

        @community_filter_keywords = Mammoth::CommunityFilterKeyword.get_all_community_filter_keywords(account_id: current_account.id, community_id: @community.id, offset: offset, limit: limit)
        return_format_json(offset, default_limit)
      end  
    end

    def create

      @community_filter_keyword = Mammoth::CommunityFilterKeyword.create!(
        account_id: current_account.id,
        keyword: community_filter_keyword_params[:keyword],
        community_id: @community.try(:id) || nil,
        is_filter_hashtag: community_filter_keyword_params[:is_filter_hashtag],
      )
      return_message("create")

    end

    def show
      ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
        return_community_filter_keyword
      end
    end

    def update

      @community_filter_keyword.update!(community_filter_keyword_params)
      return_message("update")

    end

    def destroy

      @community_filter_keyword.destroy!
      render json: {message: 'community_filter_keyword delect success!'}, status: 200 

    end

    def unban_statuses
      Mammoth::CommunityFilterStatus.where(community_filter_keyword_id: params[:id])&.destroy_all
      render json: {}, status: 200
    end
    
    private

    def return_format_json(offset, default_limit)

      unless @community_filter_keywords.empty?

        render json: @community_filter_keywords.limit(default_limit), root: 'data', 
        each_serializer: Mammoth::CommunityFilterKeywordSerializer, current_user: current_user, adapter: :json, 
        meta: {
          pagination:
          { 
            has_more_objects: @community_filter_keywords.size > default_limit ? true : false,
            offset: offset.to_i
          } 
        }
      else
        render json: {
          data: [],
          meta: {
          pagination:
          { 
            has_more_objects: false,
            offset: 0
          } 
          }
        }
      end

    end

    def return_message(str_message)

      if @community_filter_keyword
        render json: {message: "community_filter_keyword #{str_message} success!"}, status: 200
      else
        render json: {error: "community_filter_keyword #{str_message} failed!"}, status: 422
      end

    end

		def return_community_filter_keyword

			render json: @community_filter_keyword,root: 'data', serializer: Mammoth::CommunityFilterKeywordSerializer ,adapter: :json, current_user: current_user

		end

		def set_community_filter_keyword

			@community_filter_keyword = Mammoth::CommunityFilterKeyword.where(id: params[:id]).last

		end

    def set_community_id

      community_id = params[:community_id].present? ? params[:community_id] : community_filter_keyword_params[:community_id]
      @community = Mammoth::Community.where(slug: community_id).last

    end

    def community_filter_keyword_params

      params.require(:community_filter_keyword).permit(
        :community_id,
        :keyword,
        :is_filter_hashtag
      )
      
    end

  end
end
