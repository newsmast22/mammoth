module Mammoth
  class CommunityFilterStatusesDestroyWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'custom_keyword_filter', retry: true, dead: true

    def perform(status_id)
      Mammoth::CommunityFilterStatus.new.delete_filtered_statuses(status_id)
    end

  end
end

