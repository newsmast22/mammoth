module Mammoth
  class Block < Block
    self.table_name = 'blocks'
    belongs_to :account, class_name: 'Account'
    belongs_to :target_account, class_name: 'Account'
  end
end