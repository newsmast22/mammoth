module Mammoth
  class CommunityAdminSetting < ApplicationRecord
    self.table_name = 'mammoth_community_admin_settings'

    belongs_to :community_admin,class_name: "Mammoth::CommunityAdmin"

  end
end