class Mammoth::CommunitySerializer < ActiveModel::Serializer
    attributes :id, :name, :slug, :is_country_filter_on, :position, :is_recommended, :participants_count,
               :admin_following_count, :bot_account, :bio, :image_url, :header_url, :is_country_filtering,
               :description, :collection, :created_at, :updated_at


    def image_url
      object.image.url
    end

    def header_url
      object.header.url
    end

    def collection
      object.collection
    end

end