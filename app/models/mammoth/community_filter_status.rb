module Mammoth
  class CommunityFilterStatus < ApplicationRecord
    belongs_to :community_filter_keyword, class_name: "Mammoth::CommunityFilterKeyword"
    belings_to :status, class_name: "Mammoth::Status"
  end
end