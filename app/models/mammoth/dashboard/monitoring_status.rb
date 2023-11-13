module Mammoth
  class Dashboard::MonitoringStatus < ApplicationRecord
    self.table_name = 'monitoring_statuses'
    belongs_to :end_point, foreign_key: 'end_point_id'

  end
end
