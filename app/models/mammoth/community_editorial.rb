module Mammoth
  class CommunityEditorial < ApplicationRecord
    self.table_name = 'mammoth_community_editorials'

    belongs_to :account
    belongs_to :target_account, class_name: 'Account'
    validates :account_id, uniqueness: { scope: :target_account_id }

  end
end