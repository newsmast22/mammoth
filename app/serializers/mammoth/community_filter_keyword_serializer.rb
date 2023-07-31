class Mammoth::CommunityFilterKeywordSerializer < ActiveModel::Serializer
  attributes :id,:account_id,:community_id,:keyword,:created_at,:post_count

  def post_count
    0
  end
end