class Mammoth::CollectionService < BaseService
    
    def self.get_collections
        @collections = Mammoth::Collection.all.order(position: :ASC)
        data = []
        data << all_collection
        @collections.each do |collection|
            data << {
                id: collection.id,
                position: collection.position,
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
        return data
    end

    def self.all_collection 
		all_collection_count = Mammoth::Community.joins(:collection).count
	
		data = {
		  id: Mammoth::Collection.count + 1,
		  position: nil,
          name: 'All',
          slug: 'all',
		  image_file_name: nil,
		  image_content_type: nil,
		  image_file_size: nil,
          image_updated_at: Time.now,
		  community_count: all_collection_count,
		  created_at: Time.now,
		  updated_at: Time.now,
          image_url: "https://s3-eu-west-2.amazonaws.com/newsmast/mammoth/collections/images/000/000/001/original/0644f0f95a1f6945.jpeg"
		}
	  
		return data
	end 
end