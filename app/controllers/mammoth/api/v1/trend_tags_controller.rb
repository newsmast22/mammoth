module Mammoth::Api::V1
  class TrendTagsController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read}
    extend ActiveSupport::Concern

    def index
      # Assign limit = 5 as 6 if limit is nil
      # Limit always plus one 
      # Addition plus one to get has_more_object
      limit = params[:limit].present? ? params[:limit].to_i + 1 : 6
      offset = params[:offset].present? ? params[:offset] : 0
      search_tags = params[:words].present? ? params[:words] : nil
      default_limit = limit - 1

      @tag = Mammoth::Tag.search_global_hashtag(search_tags, limit, offset)

      return_search_format_json(default_limit, offset)
    end

    def get_my_community_trend_tag

      # Assign limit = 5 as 6 if limit is nil
      # Limit always plus one 
      # Addition plus one to get has_more_object
      limit = params[:limit].present? ? params[:limit].to_i + 1 : 6
      offset = params[:offset].present? ? params[:offset] : 0
      search_tags = params[:words].present? ? params[:words] : nil
      default_limit = limit - 1

      @tag = Mammoth::Tag.search_my_community_hashtag(search_tags, limit, offset,current_user)

      return_search_format_json(default_limit, offset)
    end

    private

    def return_search_format_json(default_limit, offset) 
      render json:  @tag.take(default_limit), root: 'data', 
      each_serializer: Mammoth::TagSerializer, current_user: current_user, adapter: :json, is_post_count: true,
      meta: { 
      has_more_objects: @tag.length > default_limit ? true : false,
      offset: offset.to_i
      }
    end

  end
end