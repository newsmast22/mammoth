module Mammoth
  class CommunityFilterStatus < ApplicationRecord
    belongs_to :community_filter_keyword, class_name: "Mammoth::CommunityFilterKeyword"
    belongs_to :status, class_name: "Mammoth::Status" 

    after_create :recompute_cache
    after_update :recompute_cache
    before_destroy :recompute_cache

    private 

    def recompute_cache
      DistributionWorker.perform_async(self.status_id)
    end
  end
end