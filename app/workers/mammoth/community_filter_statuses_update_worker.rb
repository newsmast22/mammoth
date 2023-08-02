module Mammoth
  class CommunityFilterStatusesUpdateWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'custom_keyword_filter', retry: true, dead: true


    def perform(params = {})

      Mammoth::CommunityFilterStatus.where(community_filter_keyword_id: params['community_filter_keyword_id'])&.destroy_all

      Mammoth::CommunityStatus.where(community_id: params['community_id']).find_in_batches(batch_size: 100).each do |community_statuses|
        community_statuses.each do |community_status|
          filter_statuses_by_keywords = Mammoth::CommunityFilterKeyword.new()
          filter_statuses_by_keywords.filter_statuses_by_keywords(params['community_id'],community_status.status_id)
        end
      end

    end

  end
end

