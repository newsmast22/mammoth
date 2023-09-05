module Mammoth
  class CommunityAdmin < ApplicationRecord
    self.table_name = 'mammoth_communities_admins'

    belongs_to :community 
    belongs_to :user

  end
end