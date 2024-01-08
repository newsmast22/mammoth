class Mammoth::CommunityBioSerializer < ActiveModel::Serializer
  attributes :id, :slug, :name, :bio, :community_hashtags
  
  def community_hashtags
    object.community_hashtags.where(is_incoming: false)
  end
end