module Mammoth
  class CommunityFilterStatus < ApplicationRecord
    belongs_to :community_filter_keyword, class_name: "Mammoth::CommunityFilterKeyword"
    belongs_to :status, class_name: "Mammoth::Status"
  end
end