module Mammoth
  class CommunityFeed < ApplicationRecord
    self.table_name = 'mammoth_community_feeds'
    belongs_to :community, class_name: "Mammoth::Community"

  end
end