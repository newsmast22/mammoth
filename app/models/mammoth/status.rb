module Mammoth
  class Status < Status
    self.table_name = 'statuses'
    include Attachmentable

    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    belongs_to :community_feed, inverse_of: :statuses
    belongs_to :account, class_name: "Mammoth::Account"
    has_and_belongs_to_many :tags,class_name: "Mammoth::Tag"
    has_many :community_users, through: :communities
    has_many :follows, through: :account, foreign_key: :account_id
    has_many :status_tags, class_name: "Mammoth::StatusTag"
    has_many :status_pins
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
    scope :last_7_days, -> { where('created_at >= ?', 7.days.ago) }

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

  
    scope :filter_statuses_with_community_admin_logic, ->(community, account) {
      Mammoth::Status.left_joins(:communities_statuses)
        .filter_statuses_with_followed_acc_ids(community.get_community_admins)
        .where(communities_statuses: { community_id: [community.id, nil] })
    }

    scope :filter_statuses_with_not_belong_any_commu_admin, ->(community) {
      Mammoth::Status.left_joins(:communities_statuses)
        .filter_statuses_with_followed_acc_ids(community.get_community_admins)
        .where(communities_statuses: { community_id: nil })
    }
    

    scope :filter_statuses_with_current_user_logic, ->(account, community) {
      Mammoth::Status.left_joins(:communities_statuses)
        .filter_statuses_with_followed_acc_ids(account.id)
        .where(communities_statuses: { community_id: community.id })
    }

    scope :filter_following_accounts, -> (account_id) {
      follow_acc_ids = joins(:follows)
                      .where("follows.account_id = :account_id", account_id: account_id)
                      .pluck("follows.target_account_id").uniq

      tag_acc_ids = joins(:tag_followed)
                    .where("tag_follows.account_id = :account_id", account_id: account_id)
                    .pluck("statuses.account_id").uniq

      excluded_account_ids = (follow_acc_ids + tag_acc_ids).uniq
      excluded_account_ids.delete(account_id)
      where(account_id: excluded_account_ids)
    }

    scope :filter_statuses_without_current_user_with_acc_ids, -> (account_ids, current_acc_id) {
      followed_acc_ids = Follow.where(account_id: account_ids).pluck(:target_account_id).map(&:to_i).uniq
      followed_acc_ids.delete(current_acc_id) if followed_acc_ids
      where(account_id: followed_acc_ids)
    }
    
    
    scope :filter_statuses_with_followed_acc_ids, -> (account_ids) {
        
      where(account_id: Follow.where(account_id: account_ids).pluck(:target_account_id).map(&:to_i).uniq)
     
    }

    scope :filter_block_mute_inactive_statuses_by_acc_ids, -> (acc_ids) {

      left_joins(account: :user)
        .where(
          "(users.id IS NULL AND accounts.domain IS NOT NULL) OR " +
          "(users.id IS NOT NULL AND users.is_active != FALSE)"
        )
        .not_blocked(acc_ids)
        .not_muted(acc_ids)

    }

    scope :not_blocked, ->(acc_ids) {
      where.not(account_id: Block.where(account_id: acc_ids).pluck(:target_account_id))
      .where.not(account_id: Block.where(target_account_id: acc_ids).pluck(:account_id))
    }

    scope :not_muted, ->(acc_ids) {
      where.not(account_id: Mute.where(account_id: acc_ids).pluck(:target_account_id))
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

    scope :filter_with_primary_timeline_logic, ->(account, user, community) {
      if !user.is_community_admin(community.id)
        primary_user_community = user.primary_user_community
        if primary_user_community.present?
          if primary_user_community.community_id == community.id && community.is_country_filtering && community.is_country_filter_on
            with_countries(account.country)
          end
        end
      end
    }

    scope :filter_statuses_with_user_and_commu, ->(account, commu) {
      joins(:communities_statuses)
        .joins("JOIN follows ON statuses.account_id = follows.target_account_id")
        .where(follows: { account_id: account.id })
        .where(communities_statuses: { community_id: commu.id })
    }



    # Combined scope for user_community_recommended_timeline
    scope :user_community_recommended_timeline, ->(param) {
      
      admin_acc_ids = param.community.get_community_admins
      acc_ids = admin_acc_ids.push(param.account.id)

      filter_statuses_with_community_admin_logic(param.community, param.account)
      .or(filter_statuses_with_current_user_logic(param.account, param.community))
      .filter_statuses_by_community_timeline_setting(param.user.id)
      .filter_with_primary_timeline_logic(param.account, param.user, param.community)
      .where(deleted_at: nil)
      .where(reply: false)
      .where(created_at: 1.week.ago..)
      .where.not(account_id: param.account.id)
      .filter_banned_statuses
      .filter_block_mute_inactive_statuses_by_acc_ids(acc_ids)
      .last_7_days
      .pagination(param.page_no, param.max_id)

    }


    scope :user_community_all_timeline, ->(param) {

      admin_acc_ids = param.community.get_community_admins
      acc_ids = admin_acc_ids.push(param.account.id)

      left_joins(:communities_statuses)
      .where(communities_statuses: { community_id: param.community.id })
      .or(filter_statuses_with_not_belong_any_commu_admin(param.community))
      .filter_statuses_by_community_timeline_setting(param.user.id)
      .filter_with_primary_timeline_logic(param.account, param.user, param.community)
      .where(deleted_at: nil)
      .where(reply: false)
      .where(created_at: 1.week.ago..)
      .filter_banned_statuses
      .filter_block_mute_inactive_statuses_by_acc_ids(acc_ids)
      .last_7_days
      .pagination(param.page_no, param.max_id)
    }
                       
    scope :all_timeline, -> (param) {
      
      joins(communities_statuses: :community)
      .filter_banned_statuses
      .where.not(mammoth_communities: { slug: "breaking_news" })
      .filter_statuses_without_rss
      .where(deleted_at: nil)
      .where(created_at: 1.week.ago..)
      .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
      .last_7_days
      .pagination(param.page_no, param.max_id)
    }
  
    scope :newsmast_timeline, -> (param) {
    
      filter_banned_statuses
      .where(is_rss_content: false)
      .where(local: true)
      .where(deleted_at: nil)
      .where(reply: false)
      .where(created_at: 1.week.ago..)
      .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
      .last_7_days
      .pagination(param.page_no, param.max_id)
    }

    scope :federated_timeline, -> (param) {
     
      filter_banned_statuses
      .where(local: false)
      .where(deleted_at: nil)
      .where(reply: false)
      .where(created_at: 1.week.ago..)
      .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
      .last_7_days
      .pagination(param.page_no, param.max_id)
    }

    scope :user_profile_timeline, -> (account_id, profile_id, max_id = nil , page_no = nil ) {

      left_joins(:status_pins)
      .where(account_id: profile_id)
      .where(deleted_at: nil)
      .where(reply: false)
      .where(created_at: 1.week.ago..)
      .filter_block_mute_inactive_statuses_by_acc_ids(account_id)
      .pin_statuses_fileter(max_id)
    }
     
    scope :my_community_timeline, -> (param) {
           
      joins(communities_statuses: :community)
      .joins(community_users: :community)
      .filter_statuses_without_rss
      .where.not(mammoth_communities: { slug: "breaking_news" })
      .where(community_users: { user_id: param.user_id })
      .filter_banned_statuses
      .where(deleted_at: nil)
      .where(created_at: 1.week.ago..)
      .filter_statuses_by_timeline_setting(param.user_id)
      .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
      .pagination(param.page_no, param.max_id)
    }
        
    scope :following_timeline, -> (param) {
      
      filter_following_accounts(param.acc_id)
      .filter_banned_statuses
      .filter_statuses_by_timeline_setting(param.user_id)
      .where(reply: false)
      .where(created_at: 1.week.ago..)
      .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
      .pagination(param.page_no, param.max_id)
    }

    scope :pagination, ->( page_no = nil, max_id ) {
     
      if page_no.nil? || !page_no.present? 
        filter_with_max_id(max_id)
        .order(id: :desc)
        .select('statuses.id') 
        .distinct
        .limit(5)
      else 
        order(id: :desc)
        .select('statuses.id') 
        .distinct
        paginate(page: page_no, per_page: 5)
      end
    }

    scope :filter_with_max_id, -> (max_id) {
      
      condition_query = if max_id.nil? || !max_id.present? 
        "statuses.id > 0"
      else
        "statuses.id < :max_id"
      end
      
      where(condition_query, max_id: max_id.to_i || 0 )
    }

    # Filter without pinned status with max_id
    # Excluded Pinnes Statuses in profile deatils timeline when paginate 
    # Edited: MKK 
    scope :filter_without_pin_with_max_id, -> (max_id) {
      condition_query = if max_id.nil? || !max_id.present? 
        "statuses.id > 0"
      else
        "statuses.id < :max_id"
      end
      
      where(condition_query, max_id: max_id.to_i || 0 )
    }

    scope :pin_statuses_fileter, -> (max_id = nil) {
      if max_id.nil? || !max.present? || max_id === ""
        joins(
          "LEFT JOIN status_pins on statuses.id = status_pins.status_id"
          ).reorder(
            Arel.sql('(case when status_pins.created_at is not null then 1 else 0 end) desc, status_pins.created_at desc, statuses.id desc')
          ).limit(5)
      else 
        where(status_pins: { id: nil } )
              .filter_with_max_id(max_id)
              .order(id: :desc)
              .distinct
              .limit(5)
      end
    }

    scope :filter_statuses_without_rss, -> {
      where(reply: false)
      .where(community_feed_id: nil)
      .where(group_id: nil)
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

    scope :filter_statuses_by_community_timeline_setting, ->(user_id){
      user = Mammoth::User.find(user_id)
      selected_filters = user.selected_user_community_filter
      common_filter_by_selected_filters(selected_filters)
    }

    scope :filter_statuses_by_timeline_setting, ->(user_id) {
      user = Mammoth::User.find(user_id)
      selected_filters = user.selected_filters_for_user
      common_filter_by_selected_filters(selected_filters) 
    }
     
    scope :common_filter_by_selected_filters, ->(selected_filters) {
      return self if selected_filters.blank?
    
      selected_countries = selected_filters.selected_countries
      selected_contributor_role = selected_filters.selected_contributor_role
      selected_voices = selected_filters.selected_voices
      selected_media = selected_filters.selected_media
    
        with_countries(selected_countries)
        .with_contributor_role(selected_contributor_role)
        .with_voice(selected_voices)
        .with_media(selected_media)
    }
    
    scope :with_countries, ->(country_alpha2_name) {
      return self if country_alpha2_name.blank?
      joins(:account).where(accounts: { country: country_alpha2_name })
    }
    
    scope :with_contributor_role, ->(id) {
      return self if id.blank?
      joins(:account).where("accounts.about_me_title_option_ids @> ARRAY[?]::integer[]", id)
    }
    
    scope :with_voice, ->(id) {
      return self if id.blank?
      joins(:account).where("accounts.about_me_title_option_ids && ARRAY[?]::integer[]", id)
    }
    
    scope :with_media, ->(id) {
      return self if id.blank?
      joins(:account).where("accounts.about_me_title_option_ids && ARRAY[?]::integer[]", id)
    }
    
    scope :filter_with_words, ->(words) {
      return self if words.blank?
      where("LOWER(statuses.text) like '%#{words}%'")
    }

    scope :filter_banned_statuses, -> { left_joins(:community_filter_statuses)
                                        .where(community_filter_statuses: { id: nil }) }

    def check_pinned_status(status_id, account_id)

      if StatusPin.exists?(status_id: status_id, account_id: account_id)
         status_id = Mammoth::Status.joins(
            "LEFT JOIN status_pins on statuses.id = status_pins.status_id"
          ).where(
            "status_pins.status_id IS NULL AND statuses.account_id = ? ", account_id
          ).order(
            "statuses.id desc"
          ).first.try(:id)

      end
      status_id
    end

  end
end