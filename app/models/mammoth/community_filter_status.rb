module Mammoth
  class CommunityFilterStatus < ApplicationRecord
    belongs_to :community_filter_keyword, class_name: "Mammoth::CommunityFilterKeyword"
    belongs_to :status, class_name: "Mammoth::Status" 

    after_create :unpush_form_cache
    after_update :unpush_form_cache

    private 

    def unpush_form_cache
      DistributionWorker.perform_async(self.status_id)
    end
  end
end