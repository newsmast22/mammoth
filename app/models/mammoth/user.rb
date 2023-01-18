module Mammoth
  class User < User
    self.table_name = 'users'
    
    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
  end
end