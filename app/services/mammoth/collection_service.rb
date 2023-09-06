class Mammoth::CollectionService < BaseService
    def initialize(params)
      @params = params
      @params.permit!
      if @params.include?(:is_virtual)
        @is_virtual = @params[:is_virtual]
      else
        @is_virtual = false
      end  
    end
    
    def get_collections
      @collections = Mammoth::Collection.all.order(position: :ASC)
      data = []
  
      @collections.each do |collection|
          data << {
              id: collection.id,
              position: collection.position,
              name: collection.name,
              slug: collection.slug,
              is_virtual: false,
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
      if @is_virtual == 'true' || @is_virtual.nil?
        data << all_collection
      end
      return data
    end

    def all_collection 
		all_collection_count = Mammoth::Community.joins(:collection).count

		data = {
		  id: Mammoth::Collection.count + 1,
		  position: nil,
      name: 'All',
      slug: 'all',
      is_virtual: true,
		  image_file_name: nil,
		  image_content_type: nil,
		  image_file_size: nil,
      image_updated_at: Time.now,
		  community_count: all_collection_count,
		  created_at: Time.now,
		  updated_at: Time.now,
      image_url: "https://newsmast-assets.s3.eu-west-2.amazonaws.com/all_collection_community_cover_photos/all_community_cover_photo.jpg",
      collection_detail_image_url: "https://newsmast-assets.s3.eu-west-2.amazonaws.com/all_collection_community_cover_photos/all_collection_cover_photo.jpg",
      description: "All posts from the communities of Newsmast and connected instances of Fediverse."
		}
	  
		return data
	end 

  def self.all_collection 
		all_collection_count = Mammoth::Community.joins(:collection).count
		data = {
		  id: Mammoth::Collection.count + 1,
		  position: nil,
      name: 'All',
      slug: 'all',
      is_virtual: true,
		  image_file_name: nil,
		  image_content_type: nil,
		  image_file_size: nil,
      image_updated_at: Time.now,
		  community_count: all_collection_count,
		  created_at: Time.now,
		  updated_at: Time.now,
      image_url: "https://newsmast-assets.s3.eu-west-2.amazonaws.com/all_collection_community_cover_photos/all_collection_cover_photo.jpg",
      collection_detail_image_url: "https://newsmast-assets.s3.eu-west-2.amazonaws.com/all_collection_community_cover_photos/all_community_cover_photo.jpg",
      description: "All posts from the communities of Newsmast and connected instances of Fediverse."
		}
	  
		return data
	end 
end