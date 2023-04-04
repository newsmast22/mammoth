class Mammoth::CommunityFeedSerializer < ActiveModel::Serializer

  attributes :id, :name, :slug, :custom_url
  
end