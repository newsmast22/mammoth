module Mammoth
  class UserCommunity < ApplicationRecord
    self.table_name = 'mammoth_communities_users'

    belongs_to :community 
    belongs_to :user
  end
end