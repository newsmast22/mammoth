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
				render json: data
			else
				@user_communities = Mammoth::User.find(current_user.id).user_communities
				user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)
				primary_community =  @user_communities.where(is_primary: true).last
				@collection  = Mammoth::Collection.where(slug: params[:collection_id]).last
				unless @collection.nil?
					@communities = @collection.communities.where.not(id: primary_community.community_id)
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
							followers: Mammoth::UserCommunity.where(community_id: community.id).size,
							collection_id: community.collection_id,
							created_at: community.created_at,
							updated_at: community.updated_at
						}
					end
					render json: {data: data  ,
					collection_data:{
						collection_image_url: @collection.image.url,
						collection_name: @collection.name
					}
				}
				else # No record found!
					render json: data
				end
			end
		end

		def show
			return_community
		end

		def create
			collection = Mammoth::Collection.find_by(slug: community_params[:collection_id])
			@community = Mammoth::Community.new()
			@community.name = community_params[:name]
			@community.slug = community_params[:slug]
			@community.description = community_params[:description]
			@community.collection_id = collection.id
			@community.save

			unless community_params[:image_data].nil?
				image = Paperclip.io_adapters.for(community_params[:image_data])
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
			@community.name = community_params[:name]
			@community.description = community_params[:description]
			@community.save

			unless community_params[:image_data].nil?
				image = Paperclip.io_adapters.for(community_params[:image_data])
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