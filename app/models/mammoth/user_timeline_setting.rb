module Mammoth
  class UserTimelineSetting < ApplicationRecord
    self.table_name = 'mammoth_user_timeline_settings'
    belongs_to :user,class_name: "Mammoth::User"
  end
end