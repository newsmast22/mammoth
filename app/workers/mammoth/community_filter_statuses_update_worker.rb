module Mammoth
  class CommunityFilterStatusesUpdateWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'custom_keyword_filter', retry: true, dead: true

    def perform(params = {})

      # Mammoth::CommunityFilterStatus.where(community_filter_keyword_id: params['community_filter_keyword_id'])&.destroy_all

      # Mammoth::CommunityStatus.new.create_statuses_by_batch_size(params['community_id'])

    end

  end
end