module Mammoth
  class CommunityBioService < BaseService

    def call_bio_hashtag(community_id = nil)
      tags_names = Mammoth::CommunityHashtag.where(is_incoming: true, community_id: community_id).pluck(:name)
      tag_ids = Tag.find_or_create_by_names(tags_names).map(&:id)

      Tag.joins("LEFT JOIN  statuses_tags ON tags.id = statuses_tags.tag_id")
      .select('tags.*')
      .where('tags.id IN (?)',tag_ids)
      .group('tags.id, statuses_tags.tag_id')
      .order('COUNT(statuses_tags.status_id) DESC').limit(10)

    end
      
  end
end
