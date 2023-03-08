module Mammoth
  class Subtitle < ApplicationRecord
    self.table_name = 'mammoth_subtitles'
    has_many :accounts, class_name: "Account"
  end
end