module Mammoth
  class CommunityFilterStatusesCreateWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'custom_keyword_filter', retry: true, dead: true

    def perform(params = {})

      if params['is_status_create'] == true

        params['community_id'].each do |community_id|
          Mammoth::CommunityFilterKeyword.new.filter_statuses_by_keywords(community_id, params['status_id'])
        end
        
      else
        # This is only call when community filter keyword when create records
        # Only need to fetch & create status when community keyword create/update
        Mammoth::CommunityStatus.new.create_statuses_by_batch_size(params['community_id'])
      end

    end

  end
end

