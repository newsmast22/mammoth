module Mammoth
  class Status < Status
    self.table_name = 'statuses'
    include Attachmentable

    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    belongs_to :community_feed, inverse_of: :statuses
    belongs_to :account, class_name: "Mammoth::Account"
    has_and_belongs_to_many :tags,class_name: "Mammoth::Tag"
    has_many :community_filter_statuses, class_name: "Mammoth::CommunityFilterStatus"
    has_many :communities_statuses, class_name: "Mammoth::CommunityStatus"
    has_many :community_users, through: :communities
    has_many :follows, through: :account 
    has_many :status_tags, class_name: "Mammoth::StatusTag"
    has_many :tag_followed, through: :status_tags

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

    scope :get_block_mute_inactive_acc_id, -> (account_id) {
      blocked_account_ids = joins(account: :blocks)
        .where("blocks.target_account_id = :account_id OR blocks.account_id = :account_id", account_id: account_id)
        .pluck("blocks.account_id, blocks.target_account_id")

      muted_account_ids = joins(account: :mutes)
        .where("mutes.account_id = :account_id", account_id: account_id)
        .pluck("mutes.target_account_id")

      inactive_account_ids = joins(account: :user)
        .where("users.is_active = ?", false)
        .pluck("accounts.id")

      excluded_account_ids = (blocked_account_ids + muted_account_ids + inactive_account_ids).uniq
      excluded_account_ids.delete(account_id)
      
      where(account_id: excluded_account_ids).pluck(:account_id)
    }

    scope :filter_following_accounts, -> (account_id) {
      follow_acc_ids = joins(:follows)
                      .where("follows.account_id = :account_id", account_id: account_id)
                      .pluck("follows.target_account_id")

      tag_acc_ids = joins(:tag_followed)
                    .where("tag_follows.account_id = :account_id", account_id: account_id)
                    .pluck("statuses.account_id")

      excluded_account_ids = (follow_acc_ids + tag_acc_ids).uniq
      excluded_account_ids.delete(account_id)
      where(account_id: excluded_account_ids)
    }

    scope :filter_block_mute_inactive_statuses, -> (account_id) {
      blocked_account_ids = joins(account: :blocks)
        .where("blocks.target_account_id = :account_id OR blocks.account_id = :account_id", account_id: account_id)
        .pluck("blocks.account_id, blocks.target_account_id")

      muted_account_ids = joins(account: :mutes)
        .where("mutes.account_id = :account_id", account_id: account_id)
        .pluck("mutes.target_account_id")

      inactive_account_ids = joins(account: :user)
        .where("users.is_active = ?", false)
        .pluck("accounts.id")

      excluded_account_ids = (blocked_account_ids + muted_account_ids + inactive_account_ids).uniq
      excluded_account_ids.delete(account_id)
      
      where.not(account_id: excluded_account_ids)
    }

    scope :blocked_account_ids, -> (account_id) {
      joins(account: :blocks)
        .where("blocks.target_account_id = :account_id OR blocks.account_id = :account_id", account_id: account_id)
        .pluck("blocks.account_id, blocks.target_account_id")
    }
  
    scope :muted_account_ids, -> (account_id) {
      joins(account: :mutes)
        .where("mutes.account_id = :account_id", account_id: account_id)
        .pluck("mutes.target_account_id")

    }
  
    scope :inactive_account_ids, -> {
        joins(account: :user)
        .where("users.is_active = ?", false)
        .pluck("accounts.id")
    
    }

    scope :filter_block_mute_inactive_acc_id, ->(account_id) {
      excluded_account_ids = excluded_account_ids(account_id)
      where.not(account_id: excluded_account_ids)
    }

    scope :newsmast_timeline, -> (max_id, excluded_ids=[]) {
    
      filter_banned_statuses
      .filter_with_max_id(max_id)
      .where.not(id: excluded_ids)
      .where(local: true)
      .where(deleted_at: nil)
      .where(reply: false)
      .limit(5)
    }

    scope :federated_timeline, -> (max_id, excluded_ids=[]) {
     
      filter_banned_statuses
      .filter_with_max_id(max_id)
      .where.not(id: excluded_ids)
      .where(local: false)
      .where(deleted_at: nil)
      .where(reply: false)
      .limit(5)
    }

    scope :all_timeline, -> (max_id, excluded_ids=[]) {
      
      joins(communities_statuses: :community)
      .filter_banned_statuses
      .filter_with_max_id(max_id)
      .where.not(id: excluded_ids)
      .where.not(mammoth_communities: { slug: "breaking_news" })
      .filter_statuses_without_rss
      .where(deleted_at: nil)
      .limit(5)
    }

    scope :my_community_timeline, -> (user_id, max_id, excluded_ids=[]) {
           
      joins(communities_statuses: :community)
      .joins(community_users: :community)
      .filter_banned_statuses
      .filter_with_max_id(max_id)
      .where.not(id: excluded_ids)
      .filter_statuses_without_rss
      .where.not(mammoth_communities: { slug: "breaking_news" })
      .where(community_users: { user_id: user_id })
      .where(deleted_at: nil)
      .filter_statuses_by_timeline_setting(user_id)
      .limit(5)
    }

    scope :following_timeline, -> (user_id, acc_id, max_id) {
      
      filter_following_accounts(acc_id)
      .filter_banned_statuses
      .filter_with_max_id(max_id)
      .filter_statuses_by_timeline_setting(user_id)
      .filter_block_mute_inactive_statuses(acc_id)
      .where(reply: false)
      .limit(5)
    }

    scope :filter_with_max_id, -> (max_id) {
      condition_query = if max_id.nil?
        "statuses.id > 0"
      else
        "statuses.id < :max_id"
      end
      where(condition_query, max_id: max_id || 0)
    }

    scope :filter_statuses_without_rss, -> {
      where(reply: false)
      .where(community_feed_id: nil)
      .where(group_id: nil)
    }

    scope :filter_statuses_by_timeline_setting, ->(user_id) {
      user = Mammoth::User.find(user_id)
      selected_filters = user.selected_filters_for_user
    
      if selected_filters.present?
        selected_countries = selected_filters.selected_countries
        selected_contributor_role = selected_filters.selected_contributor_role
        selected_voices = selected_filters.selected_voices
        selected_media = selected_filters.selected_media
        
        if selected_countries.present?
          filter_timeline_with_countries(selected_countries)
        end 

        if selected_contributor_role.present?
          filter_timeline_with_contributor_role(selected_contributor_role)
        end 
 
        if selected_voices.present?
          filter_timeline_with_voice(selected_voices)
        end

        if selected_media.present?
          filter_timeline_with_media(selected_media)
        end
      end
    }
    scope :filter_timeline_with_countries,->(country_alpah2_name) { joins(:account).where(account: { country: country_alpah2_name }) }
    scope :filter_timeline_with_contributor_role, ->(id) { joins(:account).where("accounts.about_me_title_option_ids @> ARRAY[?]::integer[]", id) }
    scope :filter_timeline_with_voice,->(id) { joins(:account).where("accounts.about_me_title_option_ids && ARRAY[?]::integer[]", id) }
    scope :filter_timeline_with_media,->(id) { joins(:account).where("accounts.about_me_title_option_ids && ARRAY[?]::integer[]", id) }

    scope :filter_with_words, ->(words) {where("LOWER(statuses.text) like '%#{words}%'")}
    scope :filter_banned_statuses, -> { left_joins(:community_filter_statuses).where(community_filter_statuses: { id: nil }).order(id: :desc) }
  end



  
end