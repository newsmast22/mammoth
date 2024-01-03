class Mammoth::CommunityFeedSerializer < ActiveModel::Serializer

  attributes :id, :name, :slug, :custom_url, :del_schedule

  attributes :feed_counts
  
  def feed_counts
    return object.feed_counts if instance_options[:is_feed_count]
    0
  end
  
end