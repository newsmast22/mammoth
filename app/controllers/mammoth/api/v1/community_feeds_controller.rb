module Mammoth::Api::V1
	class CommunityFeedsController < Api::BaseController
		before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_community_feed, only: %i[show update destroy]

    def index

      # Assign limit = 5 as 6 if limit is nil
      # Limit always plus one 
      # Addition plus one to get has_more_object

      limit = params[:limit].present? ? params[:limit].to_i + 1 : 6
      offset = params[:offset].present? ? params[:offset] : 0

      community = Mammoth::Community.find_by(slug: params[:id])
      role_name = current_user_role

      if role_name == "rss-account"
       @community_feeds = Mammoth::CommunityFeed.feeds_for_rss_account(community.id, current_user.account.id , offset, limit)
      else # community-admin
        @community_feeds = Mammoth::CommunityFeed.feeds_for_admin(community.id, offset, limit)
      end

      default_limit = limit - 1

      return_format_json(offset, default_limit)
    end

    def show
      render json: @community_feed
    end

    def create
      @community = Mammoth::Community.find_by(slug: community_feed_params[:community_id])
        @community_feed = Mammoth::CommunityFeed.create!(
            community_id: @community.id,
            name: community_feed_params[:name],
            slug: community_feed_params[:name].downcase.parameterize(separator: '_'),
            custom_url: community_feed_params[:custom_url],
            account_id: current_user.account.id
        )
      if @community_feed
        render json: @community_feed
      else
        render json: {error: 'community-feed creation failed!'}
      end

    end

    def update
      @community_feed.name = community_feed_params[:name]
      @community_feed.custom_url = community_feed_params[:custom_url]
      @community_feed.save 
      if @community_feed
        render json: @community_feed
      else
        render json: {error: 'community-feed update failed!'}
      end
    end

    def destroy
      @community_feed.update(deleted_at: Time.zone.now)
      render json: {message: 'community-feed deleted successfully!'}
    end

    private

    def return_format_json(offset, default_limit)

      unless @community_feeds.empty?

        render json: @community_feeds.limit(default_limit), root: 'data', 
        each_serializer: Mammoth::CommunityFeedSerializer, current_user: current_user, adapter: :json, 
        meta: {
          pagination:
          { 
            has_more_objects: @community_feeds.length > default_limit ? true : false,
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

		def set_community_feed
			@community_feed = Mammoth::CommunityFeed.find_by(id: params[:id])
		end

    def community_feed_params
      params.require(:community_feed).permit(
        :name,
        :slug,
        :custom_url,
        :community_id
      )
    end

  end
end