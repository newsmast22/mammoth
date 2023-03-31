module Mammoth
  class CommunityAdmin < ApplicationRecord
    self.table_name = 'mammoth_communities_admins'

    belongs_to :community 
    belongs_to :user
    has_many :community_admin_settings, class_name: "Mammoth::CommunityAdminSetting"

  end
end