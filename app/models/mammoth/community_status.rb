module Mammoth
    class CommunityStatus < ApplicationRecord
      self.table_name = 'mammoth_communities_statuses'

      belongs_to :community 
      belongs_to :status
    end
end