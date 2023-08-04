module Mammoth
  class CommunityFilterStatus < ApplicationRecord
    belongs_to :community_filter_keyword, class_name: "Mammoth::CommunityFilterKeyword"
    belongs_to :status, class_name: "Mammoth::Status"

    def delete_filtered_statuses(status_id)
      self.class.where(status_id: status_id).destroy_all
    end

  end
end