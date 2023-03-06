module Mammoth
  class Media < ApplicationRecord
    self.table_name = 'mammoth_medias'
    has_many :accounts, class_name: "Account"
  end
end