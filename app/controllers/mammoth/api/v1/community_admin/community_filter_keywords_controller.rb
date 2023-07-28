module Mammoth::Api::V1::CommunityAdmin
  class CommunityFilterKeywordsController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_community_filter_keyword, only: %i[show update destroy]
    before_action :set_community_id, only: %i[create index]

    def index
      community_filter_keywords = Mammoth::CommunityFilterKeyword.get_all_community_filter_keywords(account_id: current_account.id, community_id: @community.id, max_id: params[:max_id])

      unless community_filter_keywords.empty?
        before_limit_statuses = community_filter_keywords
        community_filter_keywords = community_filter_keywords.order(created_at: :desc).limit(5)

      data = []

      community_filter_keywords.each do |community_filter_keyword|
        data << {
          id: community_filter_keyword.account_id,
          account_id: community_filter_keyword.account_id,
          community_id: community_filter_keyword.community_id,
          keyword: community_filter_keyword.keyword,
          created_at: community_filter_keyword.created_at,
          updated_at: community_filter_keyword.updated_at,
          post_count: 0
        }
      end

        render json: {
          data: data,
          meta: {
            pagination:
            { 
              total_objects: before_limit_statuses.size,
              has_more_objects: 5 <= before_limit_statuses.size ? true : false
            } 
          }
        }
      else
        render json: {
          data: [],
          meta: {
            pagination:
            { 
              total_objects: 0,
              has_more_objects: false
            } 
          }
        }
      end
    end

    def create
      @community_filter_keyword = Mammoth::CommunityFilterKeyword.create!(
        account_id: current_account.id,
        keyword: community_filter_keyword_params[:keyword],
        community_id: @community.try(:id) || nil
      )
      if @community_filter_keyword
				render json: {message: 'community_filter_keyword create success!'}, status: 200
			else
				render json: {error: 'community_filter_keyword create failed!'}, status: 422
			end

    end

    def show
      return_community_filter_keyword
    end

    def update
      @community_filter_keyword.update!(community_filter_keyword_params)
      if @community_filter_keyword
				render json: {message: 'community_filter_keyword update success!'}, status: 200
			else
				render json: {error: 'community_filter_keyword update failed!'}, status: 422
			end
    end

    def destroy
      @community_filter_keyword.destroy!
      render json: {message: 'community_filter_keyword delect success!'}, status: 200 
    end
    
    private

		def return_community_filter_keyword
			render json: @community_filter_keyword
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
        :keyword
      )
    end

  end
end
