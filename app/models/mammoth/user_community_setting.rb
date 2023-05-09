module Mammoth
  class UserCommunitySetting < ApplicationRecord
    self.table_name = 'mammoth_user_community_settings'

    belongs_to :user,class_name: "Mammoth::User"
  end
end