module Mammoth
  class Status < Status
    self.table_name = 'statuses'
    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
  end
end