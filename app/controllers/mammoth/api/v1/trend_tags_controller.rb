module Mammoth::Api::V1
  class TrendTagsController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read}
    extend ActiveSupport::Concern

    #Begin::Original code
    #before_action :set_tags
    #End::Original code

    def index
      tag_ids = Mammoth::StatusTag
      .group("tag_id")
      .having("count(tag_id) > 0 ")
      .order("count(tag_id) desc").select('tag_id')
      .pluck(:tag_id).map(&:to_i)
      if tag_ids.any?
        @tag = Mammoth::Tag.where(id: tag_ids)
        @tag = @tag.filter_with_words(params[:words].downcase) if params[:words].present?

        left_seggession_count = 0
        if params[:limit].present?
          left_seggession_count = @tag.size - params[:limit].to_i <= 0 ? 0 : @tag.size - params[:limit].to_i
          @tag = @tag.limit(params[:limit])
        end

        render json: @tag,root: 'data', each_serializer: Mammoth::TagSerializer, adapter: :json, 
        meta: { 
          left_suggession_count: left_seggession_count
        }
      else
        render json: {
          error: "Record not found"
         }
      end
    end

    def get_my_community_trend_tag
      @user_communities = Mammoth::User.find(current_user.id).user_communities
			user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)
			if user_communities_ids.any?
        community_statuses = Mammoth::CommunityStatus.where(community_id: user_communities_ids)
				unless community_statuses.empty?
					community_statues_ids= community_statuses.pluck(:status_id).map(&:to_i)
					tag_ids = Mammoth::StatusTag
          .group("tag_id")
          .where(status_id: community_statues_ids)
          .having("count(tag_id) > 0 ")
          .order("count(tag_id) desc").select('tag_id')
          .pluck(:tag_id).map(&:to_i)
          if tag_ids.any?
            @tag = Mammoth::Tag.where(id: tag_ids)
            @tag = @tag.filter_with_words(params[:words].downcase) if params[:words].present?

            left_seggession_count = 0
            if params[:limit].present?
              left_seggession_count = @tag.size - params[:limit].to_i <= 0 ? 0 : @tag.size - params[:limit].to_i
              @tag = @tag.limit(params[:limit])
            end

            render json: @tag,root: 'data', each_serializer: Mammoth::TagSerializer, adapter: :json, 
            meta: { 
              left_suggession_count: left_seggession_count
            }
          else
            render json: {
              error: "Record not found"
             }
          end
				else
					render json: { 
            data: [],
            meta: { 
              left_suggession_count: left_seggession_count
            }
          }
				end
      end
    end

    private

    #Begin::Original code
    # def enabled?
    #   Setting.trends
    # end
  
    # def set_tags
    #   @tags = begin
    #     if enabled?
    #       tags_from_trends.limit(5)
    #     else
    #       []
    #     end
    #   end
    # end

    # def tags_from_trends
    #   Trends.tags.query.allowed
    # end
    #End::Original code
  end
end