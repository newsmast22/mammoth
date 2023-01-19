module Mammoth
  class WaitList < ApplicationRecord
    self.table_name = 'mammoth_wait_lists'
    belongs_to :contributor_role, class_name: "Mammoth::ContributorRole",  optional: true
  end
end