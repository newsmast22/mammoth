module Mammoth
  class RSSCleanupWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true, retry: 2, dead: true

    def perform

      # Remove deleted feed's statuses
      process_community_feeds(Mammoth::CommunityFeed.where.not(deleted_at: nil))

      # Remove scheduled feed's statuses
      process_community_feeds(Mammoth::CommunityFeed.where(deleted_at: nil))
      
    end

    private

      def process_community_feeds(community_feeds)
        community_feeds.find_in_batches(batch_size: 100).each do |batch|
          batch.each do |community_feed|
            Status.where(is_rss_content: true, community_feed_id: community_feed.id).each do |status|
              if without_actions?(status)
                delete_status_and_associations(status) 

                # For scheduled feed's status
                if exceeded_del_schedule?(status.created_at, community_feed.del_schedule) && community_feed.deleted_at.nil?
                  delete_status_and_associations(status) 
                end

              end
            end
          end
        end
      end

      def without_actions?(status)
        reblog = Status.find_by(reblog_of_id: status.id)

        # no likes                   no re-tweets     no comments
        status.favourites.empty? and reblog.nil? and (status.reply == false)
      end

      def exceeded_del_schedule?(status_date, del_schedule_hour)
        del_schedule_hour.hours.ago > status_date
      end

      def delete_status_and_associations(status)
        Mammoth::CommunityStatus.where(status: status).destroy_all
        status.destroy
      end

  end
end 