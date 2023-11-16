module Mammoth
  class MammothSetting < ApplicationRecord
    self.table_name = 'mammoth_settings'

    validates :thing_type, presence: true
  end
end