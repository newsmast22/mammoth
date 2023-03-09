module Mammoth::Api::V1
	class CollectionsController < Api::BaseController
		before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_collection, only: %i[show update destroy]

    def index
			@collections = Mammoth::Collection.all
			data = []
			@collections.each do |collection|
        data << {
        id: collection.id,
        name: collection.name,
        slug: collection.slug,
        image_file_name: collection.image_file_name,
        image_content_type: collection.image_content_type,
        image_file_size: collection.image_file_size,
        image_updated_at: collection.image_updated_at,
				community_count: collection.communities.ids.size,
        created_at: collection.created_at,
        updated_at: collection.updated_at,
				image_url: collection.image.url
        }
			end
				render json: data
		end

		def get_collection_by_user
			@user  = Mammoth::User.find(current_user.id)
			@user_communities= @user.user_communities
			data = []
			unless @user_communities.empty?
				ids = @user_communities.pluck(:community_id).map(&:to_i)
				collections = Mammoth::Collection.joins(:communities).where(communities: { id: ids }).distinct
				collections.each do |collection|
					data << {
						id: collection.id,
						name: collection.name,
						slug: collection.slug,
						image_file_name: collection.image_file_name,
						image_content_type: collection.image_content_type,
						image_file_size: collection.image_file_size,
						image_updated_at: collection.image_updated_at,
						created_at: collection.created_at,
						updated_at: collection.updated_at,
						image_url: collection.image.url
					}
				end
				render json: data
			else
				render json: {error: "Record not found."}
			end
		end

		def show
			return_collection
		end

		def create
			@new_status = Mammoth::Collection.new()
			@new_status.name = collection_params[:name]
			@new_status.slug = collection_params[:slug]
			@new_status.save
			unless collection_params[:image_data].nil?
				image = Paperclip.io_adapters.for(collection_params[:image_data])
				@new_status.image = image
				@new_status.save
			end
			if @new_status
				render json: @new_status
			else
				render json: {error: 'collection creation failed!'}
			end
		end

    def update
			@collection.name = collection_params[:name]
			@collection.save
			unless collection_params[:image_data].nil?
				image = Paperclip.io_adapters.for(collection_params[:image_data])
				@collection.image = image
				@collection.save
			end

			if @collection
				render json: @collection
			else
				render json: {error: 'community update failed!'}
			end
		end

		def destroy
			
		end

		def create_subtitle
			Mammoth::Subtitle.create(slug: params[:slug], name: params[:name])
			render json: {message: "saved"}
		end

		def create_media
			Mammoth::Media.create(slug: params[:slug], name: params[:name])
			render json: {message: "saved"}
		end

		def create_voice
			Mammoth::Voice.create(slug: params[:slug], name: params[:name])
			render json: {message: "saved"}
		end

		

    private

    def return_collection
			render json: @collection
		end

		def set_collection
			@collection = Mammoth::Collection.find_by(slug: params[:id])
		end

		def collection_params
			params.require(:collection).permit(:name, :slug, :image_data)
		end

  end
end