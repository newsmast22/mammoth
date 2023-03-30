module Mammoth
  class RSSCleanupWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true, retry: 2, dead: true

    def perform
      Status.where(is_rss_content: true).each do |status|
        if over_24h?(status.created_at)
          Mammoth::CommunityStatus.where(status: status).destroy_all
          status.destroy
        end
      end
    end

    private

      def over_24h?(date)
        current = Time.zone.now
        current > (date + 24.hours)
      end
  end
end 