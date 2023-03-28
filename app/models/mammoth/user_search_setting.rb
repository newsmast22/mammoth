module Mammoth
  class UserSearchSetting < ApplicationRecord
    self.table_name = 'mammoth_user_search_settings'

    belongs_to :user,class_name: "Mammoth::User"
  end
end