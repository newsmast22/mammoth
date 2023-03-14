module Mammoth
  class Status < Status
    self.table_name = 'statuses'
    include Attachmentable

    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    
    #begin::primary timeline filter
    scope :primary_timeline_filter, ->(ids) { where(id: ids,reply: false) }
    scope :filter_timeline_with_accounts,->(account_ids) {where(account_id: account_ids)}
    #end::primary timeline filter

    #begin::following timeline filter
    scope :filter_followed_tags, ->(status_ids) { where(id: status_ids,reply: false) }
    scope :filter_followed_accounts,->(account_ids) {where(account_id: account_ids, reply: false)}
    #end::following timeline  filter


   


  end
end