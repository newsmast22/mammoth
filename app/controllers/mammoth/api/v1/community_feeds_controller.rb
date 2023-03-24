module Mammoth::Api::V1
	class CommunityFeedsController < Api::BaseController
		before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_community_feed, only: %i[show update destroy]

    def index
      community = Mammoth::Community.find_by(slug: params[:id])
      @community_feeds = Mammoth::CommunityFeed.where(community_id: community.id)
      if @community_feeds.present?
        render json: @community_feeds
      else
        render json: {error: "Record not found"}
      end
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
            custom_url: community_feed_params[:custom_url]
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
      @community_feed.destroy
      render json: {error: 'community-feed deleted successfully!'}
    end

    private

		def set_community_feed
			@community_feed = Mammoth::CommunityFeed.find_by(slug: params[:id])
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