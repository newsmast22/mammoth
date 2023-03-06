module Mammoth
  class Voice < ApplicationRecord
    self.table_name = 'mammoth_voices'
    has_many :accounts, class_name: "Account"
  end
end