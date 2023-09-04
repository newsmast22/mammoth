class Mammoth::CommunityFilterKeywordSerializer < ActiveModel::Serializer
  attributes :id,:account_id,:community_id,:keyword,:created_at,:post_count,:is_filter_hashtag

  def post_count
    object.community_filter_statuses.size
  end
  
end