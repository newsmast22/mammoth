module Mammoth
    class CommunityStatus < ApplicationRecord
      self.table_name = 'mammoth_communities_statuses'

      include Attachmentable

      has_and_belongs_to_many :Community

      has_and_belongs_to_many :Status

    end
end