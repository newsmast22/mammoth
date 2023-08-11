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

    scope :filter_block_mute_inactive_acc_id, ->(account_id) {
      blocked_account_ids = joins("INNER JOIN blocks ON statuses.account_id = blocks.account_id")
                             .where("blocks.target_account_id = ? OR blocks.account_id = ?", account_id, account_id)
                             .pluck("blocks.account_id, blocks.target_account_id")
    
      muted_account_ids = joins("INNER JOIN mutes ON statuses.account_id = mutes.target_account_id")
                           .where("mutes.account_id = ?", account_id)
                           .pluck("mutes.target_account_id")
    
      inactive_account_ids = joins(account: :user)
                             .where("users.is_active = ?", false)
                             .pluck("accounts.id")
    
      excluded_account_ids = (blocked_account_ids + muted_account_ids + inactive_account_ids).uniq
      excluded_account_ids.delete(account_id)
      where.not(account_id: excluded_account_ids)
    }

    scope :newsmast_timeline, -> (max_id) {
      condition_query = if max_id.nil?
        "statuses.id > ?"
      else
        "statuses.id < ?"
      end

        where(condition_query, max_id || 0)
      .where(local: true)
      .where(deleted_at: nil)
      .select("statuses.id, statuses.account_id")
    }

    scope :federated_timeline, -> (max_id) {
      condition_query = if max_id.nil?
        "statuses.id > ?"
      else
        "statuses.id < ?"
      end

        where(condition_query, max_id || 0)
      .where(local: false)
      .where(deleted_at: nil)
      .select("statuses.id, statuses.account_id")
    }

    scope :primary_timeline, -> (max_id) {
      condition_query = if max_id.nil?
        "statuses.id > ?"
      else
        "statuses.id < ?"
      end
            joins("JOIN mammoth_communities_statuses ON statuses.id = mammoth_communities_statuses.status_id")
            .joins("JOIN mammoth_communities ON mammoth_communities_statuses.community_id = mammoth_communities.id")
            .where(condition_query, max_id || 0)
            .where.not("mammoth_communities.slug" => "breaking_news")
            .where("statuses.reply = FALSE")
            .where("statuses.community_feed_id IS NULL")
            .where("statuses.group_id IS NULL")
            .where("statuses.deleted_at IS NULL")
            .select("statuses.id, statuses.account_id")            
    }
    
    scope :my_community_timeline, -> (user_id, max_id) {
      condition_query = if max_id.nil?
        "statuses.id > ?"
      else
        "statuses.id < ?"
      end

            joins("JOIN mammoth_communities_statuses AS commu_status ON statuses.id = commu_status.status_id")
            .joins("JOIN mammoth_communities AS commu ON commu_status.community_id = commu.id")
            .joins("JOIN mammoth_communities_users AS commu_usr ON commu_usr.community_id = commu.id")
            .where(condition_query, max_id || 0)
            .where("statuses.reply = FALSE")
            .where("statuses.community_feed_id IS NULL")
            .where("statuses.group_id IS NULL")
            .where.not("commu.slug" => "breaking_news")
            .where("commu_usr.user_id" => user_id)
            .where("statuses.deleted_at IS NULL")
            .select("statuses.id, statuses.account_id")            
    }

    scope :filter_statuses_by_timeline_setting, ->(user_id) {
      user = Mammoth::User.where(id: user_id).take
      selected_filters = user.selected_filters_for_user
    
      if selected_filters.present?
        selected_countries = selected_filters.selected_countries
        selected_contributor_role = selected_filters.selected_contributor_role
        selected_voices = selected_filters.selected_voices
        selected_media = selected_filters.selected_media
    
        filtered_accounts = Mammoth::Account.all # Initialize with all accounts
        
        if selected_countries.present?
          filtered_accounts = filtered_accounts.filter_timeline_with_countries(selected_countries)
        elsif selected_contributor_role.present?
          filtered_accounts = filtered_accounts.filter_timeline_with_contributor_role(selected_contributor_role)
        elsif selected_voices.present?
          filtered_accounts = filtered_accounts.filter_timeline_with_voice(selected_voices)
        elsif selected_media.present?
          filtered_accounts = filtered_accounts.filter_timeline_with_media(selected_media)
        end
        joins(:account).merge(filtered_accounts)
      else
        all # Return all statuses if no filters are selected
      end
    }
    
    scope :filter_with_words, ->(words) {where("LOWER(statuses.text) like '%#{words}%'")}
    scope :filter_banned_statuses, -> { left_joins(:community_filter_statuses).where(community_filter_statuses: { id: nil }).order(id: :desc) }
  end
end