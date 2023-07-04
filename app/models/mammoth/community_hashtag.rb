module Mammoth
  class CommunityHashtag < ApplicationRecord
    self.table_name = 'mammoth_community_hashtags'
    belongs_to :community, class_name: "Mammoth::Community"
  end
end