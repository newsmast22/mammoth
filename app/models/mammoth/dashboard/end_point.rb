module Mammoth
  class Dashboard::EndPoint < ApplicationRecord
    self.table_name = 'end_points'
    has_many :monitoring_statuses

  end
end
