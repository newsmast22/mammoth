module Mammoth
  class CommunityFeed < ApplicationRecord
    self.table_name = 'mammoth_community_feeds'
    belongs_to :community, class_name: "Mammoth::Community"
    belongs_to :account
    has_many :statuses, class_name: "Mammoth::Status", inverse_of: :community_feed

    scope :feeds_for_admin, -> (community_id) { joins("
      LEFT JOIN statuses ON statuses.community_feed_id = mammoth_community_feeds.id"
      )
      .select("mammoth_community_feeds.*,COUNT(statuses.id) as feed_counts"
      )
      .where("mammoth_community_feeds.community_id = :community_id AND mammoth_community_feeds.deleted_at IS NULL",
        community_id: community_id, 
       )
      .order("mammoth_community_feeds.name ASC")
      .group("mammoth_community_feeds.id")
    }
      
    scope :feeds_for_rss_account, ->(community_id,account_id) { joins("
      LEFT JOIN statuses ON statuses.community_feed_id = mammoth_community_feeds.id"
      )
      .select("mammoth_community_feeds.*,COUNT(statuses.id) as feed_counts"
      )
      .where("mammoth_community_feeds.community_id = :community_id AND mammoth_community_feeds.account_id = :account_id AND mammoth_community_feeds.deleted_at IS NULL",
        community_id: community_id, account_id: account_id, 
       )
      .order("mammoth_community_feeds.name ASC")
      .group("mammoth_community_feeds.id")
    }

    after_save :invoke_rss_worker

    private

      def invoke_rss_worker
        json = {
          'is_callback' =>  true,
          'rss_feed_url' => custom_url,
          'account_id' =>   account_id,
          'community_id' => community_id,
          'feed_id' => self.id
        }
        Mammoth::RSSCreatorWorker.perform_async(json)
      end
  end
end