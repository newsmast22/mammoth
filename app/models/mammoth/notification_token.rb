module Mammoth
  class NotificationToken < ApplicationRecord
    self.table_name = 'mammoth_notification_tokens'
    belongs_to :account
  end
end