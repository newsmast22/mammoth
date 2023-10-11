module Mammoth::Api::V1
  class TrendTagsController < Api::BaseController
    before_action :require_user!, except: [:index]
		before_action -> { doorkeeper_authorize! :read}
    before_action :set_tags, only: [:index ,:get_my_community_trend_tag] 

    DEFAULT_TAGS_LIMIT = 10

    extend ActiveSupport::Concern

    def index

      return_search_format_json

    end

    def get_my_community_trend_tag

      return_search_format_json

    end

    private

    def return_search_format_json
      render json:  @tags, root: 'data', 
      each_serializer: Mammoth::TagSerializer, current_user: current_user, adapter: :json,
      meta: { 
        has_more_objects: records_continue?, 
        offset: offset_param
      }
    end

    def enabled?
      Setting.trends
    end
  
    def set_tags
      if params[:words].present?
        tags = Search.new(search_results)
        @tags = tags.hashtags
      else
        @tags = begin
          if enabled?
            tags_from_trends.offset(offset_param).limit(limit_param(DEFAULT_TAGS_LIMIT))
          else
            []
          end
        end  
      end

      @tags = @tags || []
    end

    def search_results
      SearchService.new.call(
        params[:words].present? ? params[:words]&.strip : nil,
        current_account,
        limit_param(DEFAULT_TAGS_LIMIT),
        params.merge(type: "hashtags", resolve: truthy_param?(:resolve), exclude_unreviewed: truthy_param?(:exclude_unreviewed))
      )
    end

    def tags_from_trends
      Trends.tags.query.allowed
    end

    def offset_param
      params[:offset].to_i
    end

    def records_continue?
      @tags.size == limit_param(DEFAULT_TAGS_LIMIT)
    end

  end
end