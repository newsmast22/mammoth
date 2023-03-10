module Mammoth
  class Status < Status
    self.table_name = 'statuses'
    include Attachmentable

    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    
    scope :primary_timeline_filter, ->(ids) { where(id: ids,reply: false) }
    scope :primary_timeline_accounts_filter,->(account_ids) {where(account_id: account_ids)}
   


  end
end