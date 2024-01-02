class Mammoth::CommunityFeedSerializer < ActiveModel::Serializer

  attributes :id, :name, :slug, :custom_url, :feed_counts, :del_schedule

  def feed_counts
    object.statuses.count
  end
  
end