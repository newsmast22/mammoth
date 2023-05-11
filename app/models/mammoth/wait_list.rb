module Mammoth
  class WaitList < ApplicationRecord
    self.table_name = 'mammoth_wait_lists'
    has_one :user, inverse_of: :wait_list
    belongs_to :contributor_role, class_name: "Mammoth::ContributorRole",  optional: true
  end
end