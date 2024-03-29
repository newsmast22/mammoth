module Mammoth
  class CommunityFeed < ApplicationRecord
    self.table_name = 'mammoth_community_feeds'
    belongs_to :community, class_name: "Mammoth::Community"
    belongs_to :account
    has_many :statuses, class_name: "Mammoth::Status", inverse_of: :community_feed

    validates :slug, :presence => true, :uniqueness => {:scope => :community_id , conditions: -> { where(deleted_at: nil)} }

    scope :feeds_for_admin, -> (community_id, offset, limit) { joins("
      LEFT OUTER JOIN statuses ON statuses.community_feed_id = mammoth_community_feeds.id"
      )
      .select("mammoth_community_feeds.id,mammoth_community_feeds.name,mammoth_community_feeds.slug,mammoth_community_feeds.custom_url,
      mammoth_community_feeds.deleted_at,mammoth_community_feeds.del_schedule"
      )
      .where("mammoth_community_feeds.community_id = :community_id AND mammoth_community_feeds.deleted_at IS NULL",
        community_id: community_id, 
       )
      .order("mammoth_community_feeds.name ASC")
      .group("mammoth_community_feeds.id")
      .limit(limit)
      .offset(offset)
    }
      
    scope :feeds_for_rss_account, ->(community_id, account_id, offset, limit) { joins("
      LEFT OUTER JOIN statuses ON statuses.community_feed_id = mammoth_community_feeds.id"
      )
      .select("mammoth_community_feeds.id,mammoth_community_feeds.name,mammoth_community_feeds.slug,mammoth_community_feeds.custom_url,
      mammoth_community_feeds.deleted_at,mammoth_community_feeds.del_schedule"
      )
      .where("mammoth_community_feeds.community_id = :community_id AND mammoth_community_feeds.account_id = :account_id AND mammoth_community_feeds.deleted_at IS NULL",
        community_id: community_id, account_id: account_id, 
       )
      .order("mammoth_community_feeds.name ASC")
      .group("mammoth_community_feeds.id")
      .limit(limit)
      .offset(offset)
    }

    after_save :invoke_rss_worker

    private

      def invoke_rss_worker
        # When record created/updated deleted_at will be null => is_callback: true.
        # When record deleted deleted_at will be null  => is_callback: false.
        json = {
          'is_callback'   => self.deleted_at.nil?,
          'url'  => custom_url,
          'account_id'    => account_id,
          'community_id'  => community_id,
          'feed_id'       => self.id
        }
        Mammoth::RSSCreatorWorker.perform_async(json) if self.deleted_at.nil?
      end
  end
end