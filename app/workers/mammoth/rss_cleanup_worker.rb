module Mammoth
  class RSSCleanupWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true, retry: 2, dead: true

    def perform
      Status.where(is_rss_content: true).each do |status|
        if over_definded_duration_h?(status.created_at) && without_actions?(status)
          Mammoth::CommunityStatus.where(status: status).destroy_all
          status.destroy
        end
      end
    end

    private

      def without_actions?(status)
        reblog = Status.find_by(reblog_of_id: status.id)

        # no likes                   no re-tweets     no comments
        status.favourites.empty? and reblog.nil? and (status.reply == false)
      end

      def over_definded_duration_h?(date)
        12.hours.ago > date
      end
  end
end 