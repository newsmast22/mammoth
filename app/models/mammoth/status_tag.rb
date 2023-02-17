module Mammoth
  class StatusTag < ApplicationRecord
    self.table_name = 'statuses_tags'
    include Attachmentable

    belongs_to :tag 
    belongs_to :status
  end
end