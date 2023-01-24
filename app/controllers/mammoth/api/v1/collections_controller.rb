module Mammoth::Api::V1
	class CollectionsController < Api::BaseController
		skip_before_action :require_authenticated_user!
		before_action :set_collection, only: %i[show update destroy]

    def index
			@collections = Mammoth::Collection.all
			render json: @collections
		end

		def show
			return_collection
		end

		def create
			@collection = Mammoth::Collection.new(collection_params)
			if @collection.save
				return_collection
			else
				render json: {error: 'collection creation failed!'}
			end
		end

    def update
			if @collection.update(collection_params)
				return_collection
			else
				render json: {error: 'collection update failed!'}
			end
		end

		def destroy
			
		end

    private

    def return_collection
			render json: @collection
		end

		def set_collection
			@collection = Mammoth::Collection.find_by(slug: params[:id])
		end

		def collection_params
			params.require(:collection).permit(:name, :slug, :image)
		end

  end
end