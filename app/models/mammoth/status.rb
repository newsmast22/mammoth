module Mammoth
  class Status < Status
    self.table_name = 'statuses'
    include Attachmentable

    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    belongs_to :community_feed, inverse_of: :statuses
    has_and_belongs_to_many :tags,class_name: "Mammoth::Tag"

    
    scope :filter_with_community_status_ids, ->(ids) { where(id: ids,reply: false) }

    scope :filter_with_community_status_ids_without_rss, ->(ids) { where(id: ids,reply: false,community_feed_id: nil,group_id: nil) }

    scope :filter_timeline_with_accounts,->(account_ids) {where(account_id: account_ids)}
    scope :filter_followed_accounts,->(account_ids) {where(account_id: account_ids, reply: false)}
    scope :filter_with_status_ids, ->(status_ids,current_account_id) { where(id: status_ids, reply: false).where.not(account_id: current_account_id) }
    scope :filter_without_community_status_ids, ->(status_ids) { where.not(id: status_ids).where(reply: false) }


    scope :filter_is_only_for_followers, ->(account_ids) { where(is_only_for_followers: false).or(where(is_only_for_followers: true, account_id: account_ids)) }
    scope :filter_is_only_for_followers_community_statuses, ->(status_ids,account_ids) { where(id: status_ids, reply: false,is_only_for_followers: false).or(where(is_only_for_followers: true, account_id: account_ids,reply: false)) }
    scope :filter_is_only_for_followers_profile_details, ->(account_id) {where(account_id: account_id, reply: false)}
    scope :filter_mute_accounts,->(account_ids) {where.not(account_id: account_ids, reply: false)}
    scope :filter_without_status_account_ids, ->(status_ids,account_ids) { where.not(id: status_ids, account_id:account_ids ).where(reply: false) }
    scope :filter_blocked_statuses,->(blocked_status_ids) {where.not(id: blocked_status_ids)}

    scope :blocked_account_status_ids, -> (blocked_account_ids) {where(account_id: blocked_account_ids, reply: false)}
    scope :blocked_reblog_status_ids, -> (blocked_status_ids) {where(reblog_of_id: blocked_status_ids, reply: false)}

    scope :fetch_all_blocked_status_ids, -> (blocked_status_ids) {
      where(id: blocked_status_ids).or(where(reblog_of_id:blocked_status_ids ))
    }

    scope :filter_with_words, ->(words) {where("LOWER(statuses.text) like '%#{words}%'")}

  end
end