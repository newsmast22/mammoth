module Mammoth::Api::V1
  class TrendTagsController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read}
    extend ActiveSupport::Concern

    def index
      sql_query = "AND LOWER(tags.name) like '%#{params[:words].downcase}%' OR LOWER(tags.display_name) like '%#{params[:words].downcase}%' " if params[:words].present?

      @tag =Mammoth::Tag
        .joins(:statuses_tags)
        .select('tags.*, count(statuses_tags.tag_id) as tag_count')
        .where("tags.id > 1 #{sql_query}")
        .group('tags.id')
        .order("count(statuses_tags.tag_id) desc").limit(params[:limit])
      if @tag.present?        
        #@tag = @tag.filter_with_words(params[:words].downcase) if params[:words].present?
        left_seggession_count = 0
        if params[:limit].present?
          left_seggession_count = (@tag.to_a.size- params[:limit].to_i) <= 0 ? 0 : @tag.to_a.size- params[:limit].to_i
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
      sql_query = "AND LOWER(tags.name) like '%#{params[:words].downcase}%' OR LOWER(tags.display_name) like '%#{params[:words].downcase}%' " if params[:words].present?
			if user_communities_ids.any?
        community_statuses = Mammoth::CommunityStatus.where(community_id: user_communities_ids)
				unless community_statuses.empty?
					community_statues_ids= community_statuses.pluck(:status_id).map(&:to_i)
          @tag =Mammoth::Tag
          .joins(:statuses_tags)
          .where(statuses_tags: {status_id: community_statues_ids} )
          .where("tags.id > 1 #{sql_query}")
          .select('tags.*, count(statuses_tags.tag_id) as tag_count')
          .group('tags.id')
          .order("count(statuses_tags.tag_id) desc").limit(params[:limit])
          if @tag.present?
            #@tag = @tag.filter_with_words(params[:words].downcase) if params[:words].present?

            left_seggession_count = 0
            if params[:limit].present?
              left_seggession_count = @tag.to_a.size - params[:limit].to_i <= 0 ? 0 : @tag.to_a.size - params[:limit].to_i
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
  end
end