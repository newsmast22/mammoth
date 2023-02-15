module Mammoth::Api::V1
  class TrendTagsController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read}
    before_action :set_tags

    def index
      render json: @tags, each_serializer: Mammoth::TagSerializer, relationships: TagRelationshipsPresenter.new(@tags, current_user&.account_id)
    end

    private

    def enabled?
      Setting.trends
    end
  
    def set_tags
      @tags = begin
        if enabled?
          tags_from_trends.limit(10)
        else
          []
        end
      end
    end
  
    def tags_from_trends
      Trends.tags.query.allowed
    end
  end
end