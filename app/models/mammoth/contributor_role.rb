module Mammoth
  class ContributorRole < ApplicationRecord
    self.table_name = 'mammoth_contributor_roles'
    has_many :waitlists, class_name: "Mammoth::Waitlist"
  end
end