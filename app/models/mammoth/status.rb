module Mammoth
  class Status < Status
    self.table_name = 'statuses'
    include Attachmentable

    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    
    scope :filter_with_community_status_ids, ->(ids) { where(id: ids,reply: false) }
    scope :filter_timeline_with_accounts,->(account_ids) {where(account_id: account_ids)}
    scope :filter_followed_accounts,->(account_ids) {where(account_id: account_ids, reply: false)}
    scope :filter_with_status_ids, ->(status_ids) { where.not(id: status_ids).where(reply: false) }

    scope :filter_is_only_for_followers, ->(account_ids) { where(is_only_for_followers: false).or(where(is_only_for_followers: true, account_id: account_ids)) }
    scope :filter_is_only_for_followers_community_statuses, ->(status_ids,account_ids) { where(id: status_ids, reply: false,is_only_for_followers: false).or(where(is_only_for_followers: true, account_id: account_ids,reply: false)) }
    scope :filter_is_only_for_followers_profile_details, ->(account_id) {where(account_id: account_id, reply: false)}
    
    scope :filter_with_words, ->(words) {where("LOWER(statuses.text) like '%#{words}%' OR LOWER(statuses.spoiler_text) like '%#{words}%'")}

  end
end