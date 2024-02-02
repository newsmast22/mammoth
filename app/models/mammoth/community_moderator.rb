module Mammoth
  class CommunityModerator < ApplicationRecord
    self.table_name = 'mammoth_community_moderators'

    belongs_to :account
    belongs_to :target_account, class_name: 'Account'
    validates :account_id, uniqueness: { scope: :target_account_id }

  end
end