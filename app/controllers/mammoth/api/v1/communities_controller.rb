module Mammoth::Api::V1
	class CommunitiesController < Api::BaseController
		skip_before_action :require_authenticated_user!
		before_action :set_community, only: %i[show update destroy]

		def index
			@collection  = Mammoth::Collection.find_by(slug: params[:collection_id])
			@communities = @collection.communities
			render json: @communities
		end

		def show
			return_community
		end

		def create
			collection = Mammoth::Collection.find_by(slug: community_params[:collection_id])
			@community = Mammoth::Community.new(community_params)
			@community.collection_id = collection.id
			if @community.save
				return_community
			else
				render json: {error: 'community creation failed!'}
			end
		end

		def update
			if @community.update(community_params)
				return_community
			else
				render json: {error: 'community creation failed!'}
			end
		end

		def destroy
			
		end

		private

		def return_community
			render json: @community
		end

		def set_community
			@community = Mammoth::Community.find_by(slug: params[:id])
		end

		def community_params
			params.require(:community).permit(:name, :slug, :image_data, :description, :collection_id)
		end
	end
end