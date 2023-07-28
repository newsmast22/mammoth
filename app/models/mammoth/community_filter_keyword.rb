module Mammoth
  class CommunityFilterKeyword < ApplicationRecord
    belongs_to :community, class_name: "Mammoth::Community"
    belongs_to :account, class_name: "Account"

  end
end