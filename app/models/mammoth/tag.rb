module Mammoth
  class Tag < Tag
    self.table_name = 'tags'

    has_many :status_tags, class_name: "Mammoth::StatusTag", foreign_key: "tag_id"
    has_and_belongs_to_many :statuses, through: :status_tags

    has_many :tag_followed, class_name: "Mammoth::TagFollow", foreign_key: "tag_id"
    has_and_belongs_to_many :accounts, through: :tag_followed

    scope :filter_with_words, ->(words) { where("LOWER(tags.name) like '%#{words}%' OR LOWER(tags.display_name) like '%#{words}%' ") }

    def self.search_global_hashtag(search_tags, limit, offset)

      sql_query = "AND LOWER(tags.name) like '%#{search_tags.downcase}%' OR LOWER(tags.display_name) like '%#{search_tags.downcase}%' " unless search_tags.nil?

      tag =Mammoth::Tag
        .joins(:statuses_tags)
        .select('tags.*, count(statuses_tags.tag_id) as tag_count')
        .where("tags.id > 1 #{sql_query}")
        .group('tags.id')
        .order("count(statuses_tags.tag_id) desc").limit(limit).offset(offset)

      return tag
    end

    def self.search_my_community_hashtag(search_tags, limit, offset,current_user)

      @user_communities = Mammoth::User.find(current_user.id).user_communities
			user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)

      sql_query = "AND LOWER(tags.name) like '%#{search_tags.downcase}%' OR LOWER(tags.display_name) like '%#{search_tags.downcase}%' " unless search_tags.nil?

      if user_communities_ids.any?
        community_statuses = Mammoth::CommunityStatus.where(community_id: user_communities_ids)
        unless community_statuses.empty?
					community_statues_ids= community_statuses.pluck(:status_id).map(&:to_i)
          tag = Mammoth::Tag
          .joins(:statuses_tags)
          .where(statuses_tags: {status_id: community_statues_ids} )
          .where("tags.id > 1 #{sql_query}")
          .select('tags.*, count(statuses_tags.tag_id) as tag_count')
          .group('tags.id')
          .order("count(statuses_tags.tag_id) desc").limit(limit).offset(offset)
          return tag
				else
					return []
				end
      else
        return []
      end
      
    end
    
  end
end