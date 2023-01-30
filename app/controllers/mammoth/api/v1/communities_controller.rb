module Mammoth::Api::V1
	class CommunitiesController < Api::BaseController
		before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_community, only: %i[show update destroy]

		def index
			data = []
			if params[:collection_id].nil?
				@communities = Mammoth::Community.all
				@communities.each do |community|
					data << {
						id: community.id,
						name: community.name,
						slug: community.slug,
						image_file_name: community.image_file_name,
						image_content_type: community.image_content_type,
						image_file_size: community.image_file_size,
						image_updated_at: community.image_updated_at,
						description: community.description,
						image_url: community.image.url,
						collection_id: community.collection_id,
						created_at: community.created_at,
						updated_at: community.updated_at
					}
				end
			else
				user_communities_ids  = Mammoth::User.find(current_user.id).user_communities.pluck(:community_id).map(&:to_i)
				@collection  = Mammoth::Collection.find_by(slug: params[:collection_id])
				@communities = @collection.communities
				@communities.each do |community|
					data << {
						id: community.id,
						name: community.name,
						slug: community.slug,
						is_joined: user_communities_ids.include?(community.id), 
						image_file_name: community.image_file_name,
						image_content_type: community.image_content_type,
						image_file_size: community.image_file_size,
						image_updated_at: community.image_updated_at,
						description: community.description,
						image_url: community.image.url,
						collection_id: community.collection_id,
						created_at: community.created_at,
						updated_at: community.updated_at
					}
				end
			end
			render json: data
		end

		def show
			return_community
		end

		def create
			time = Time.new
			collection = Mammoth::Collection.find_by(slug: community_params[:collection_id])
			@community = Mammoth::Community.new()
			@community.name = community_params[:name]
			@community.slug = community_params[:slug]
			@community.description = community_params[:description]
			@community.collection_id = collection.id
			@community.save

			unless community_params[:image_data].nil?
				content_type = "image/jpg"
				image = Paperclip.io_adapters.for(community_params[:image_data])
				image.original_filename = "community-#{time.usec.to_s}-#{}.jpg"
				@community.image = image
				@community.save
			end
			if @community
				render json: @community
			else
				render json: {error: 'community creation failed!'}
			end
		end

		def update
			time = Time.new
			@community.name = community_params[:name]
			@community.description = community_params[:description]
			@community.save

			unless community_params[:image_data].nil?
				content_type = "image/jpg"
				image = Paperclip.io_adapters.for(community_params[:image_data])
				image.original_filename = "community-#{time.usec.to_s}-#{}.jpg"
				@community.image = image
				@community.save
			end

			if @community
				render json: @community
			else
				render json: {error: 'community update failed!'}
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