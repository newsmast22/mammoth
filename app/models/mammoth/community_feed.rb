module Mammoth
  class CommunityFeed < ApplicationRecord
    self.table_name = 'mammoth_community_feeds'
    belongs_to :community, class_name: "Mammoth::Community"
    belongs_to :account
    has_many :statuses, class_name: "Mammoth::Status", inverse_of: :community_feed

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