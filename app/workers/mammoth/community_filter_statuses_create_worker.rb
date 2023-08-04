module Mammoth
  class CommunityFilterStatusesCreateWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'custom_keyword_filter', retry: true, dead: true

    def perform(params = {})

      if params['is_status_create'] == true
        Mammoth::CommunityFilterKeyword.new.filter_statuses_by_keywords(params['community_id'],params['status_id'])
      else
        Mammoth::CommunityStatus.new.create_statuses_by_batch_size(params['community_id'])
      end

    end

  end
end

