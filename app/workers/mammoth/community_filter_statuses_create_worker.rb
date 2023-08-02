module Mammoth
  class CommunityFilterStatusesCreateWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'custom_keyword_filter', retry: true, dead: true


    def perform(params = {})

      if params['is_status_create'] == true
        create_community_filter_statuses(params['community_id'],params['status_id'])
      else
        Mammoth::CommunityStatus.where(community_id: params['community_id']).find_in_batches(batch_size: 100).each do |community_statuses|
          community_statuses.each do |community_status|
            create_community_filter_statuses(params['community_id'],community_status.status_id)
          end
        end
      end

    end

    private

    def create_community_filter_statuses(community_id,status_id)
      filter_statuses_by_keywords = Mammoth::CommunityFilterKeyword.new()
      filter_statuses_by_keywords.filter_statuses_by_keywords(community_id, status_id)
    end

  end
end

