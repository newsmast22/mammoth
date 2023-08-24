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
                      .pluck("follows.target_account_id").uniq

      tag_acc_ids = joins(:tag_followed)
                    .where("tag_follows.account_id = :account_id", account_id: account_id)
                    .pluck("statuses.account_id").uniq

      excluded_account_ids = (follow_acc_ids + tag_acc_ids).uniq
      excluded_account_ids.delete(account_id)
      where(account_id: excluded_account_ids)
    }

    scope :filter_with_commu_admin_acc_ids, -> (account_ids) {

      follow_acc_ids = account_followed_ids = Follow.where(account_id: account_ids).pluck(:target_account_id).map(&:to_i).uniq 
                        
      where(account_id: follow_acc_ids)
    }

    scope :filter_block_mute_inactive_statuses_by_acc_ids, -> (current_user_acc_id, admin_acc_ids) {
        acc_ids = admin_acc_ids.push(current_user_acc_id)
        blocked_account_ids = joins(account: :blocks)
        .where("blocks.target_account_id IN (:account_ids) OR blocks.account_id IN (:account_ids)", account_ids: acc_ids)
        .pluck("blocks.account_id, blocks.target_account_id")

      muted_account_ids = joins(account: :mutes)
        .where("mutes.account_id IN (:account_ids)", account_ids: acc_ids)
        .pluck("mutes.target_account_id")

      inactive_account_ids = joins(account: :user)
        .where("users.is_active = ?", false)
        .pluck("accounts.id")

      excluded_account_ids = (blocked_account_ids + muted_account_ids + inactive_account_ids).uniq
      excluded_account_ids.delete(acc_ids)
      
      where.not(account_id: excluded_account_ids)
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
            filter_timeline_with_countries(account.country)
          end
        end
      end
    }
  
    scope :user_community_recommended_timeline, ->(max_id, account, user, community, page_no=nil) {
      
      left_joins(:communities_statuses)
      .filter_with_commu_admin_acc_ids(community.get_community_admins)
      .filter_block_mute_inactive_statuses_by_acc_ids(account.id, community.get_community_admins)
      .filter_statuses_by_community_timeline_setting(user.id)
      .filter_with_primary_timeline_logic(account, user, community)
      .where("mammoth_communities_statuses.community_id = :community_id OR mammoth_communities_statuses.id IS NULL", community_id: community.id)
      .where(deleted_at: nil)
      .where(reply: false)
      .filter_banned_statuses
      .pagination(page_no, max_id)
    }

    scope :user_community_all_timeline, ->(max_id, account, user, community, page_no=nil) {
      joins(communities_statuses: :community)
      .filter_block_mute_inactive_statuses_by_acc_ids(account.id, community.get_community_admins) 
      .filter_statuses_by_community_timeline_setting(user.id)
      .filter_with_primary_timeline_logic(account, user, community)
      .where("mammoth_communities.slug = :community_slug", community_slug: community.slug)
      .where(deleted_at: nil)
      .where(reply: false)
      .filter_banned_statuses
      .pagination(page_no, max_id)
    }
                       
    scope :all_timeline, -> (max_id, excluded_ids=[], page_no=nil) {
      joins(communities_statuses: :community)
      .filter_banned_statuses
      .where.not(id: excluded_ids)
      .where.not(mammoth_communities: { slug: "breaking_news" })
      .filter_statuses_without_rss
      .where(deleted_at: nil)
      .pagination(page_no, max_id)
    }
  
    

    scope :newsmast_timeline, -> (max_id, excluded_ids=[], page_no=nil) {
    
      filter_banned_statuses
      .where(is_rss_content: false)
      .where.not(id: excluded_ids)
      .where(local: true)
      .where(deleted_at: nil)
      .where(reply: false)
      .pagination(page_no, max_id)
    }

    scope :federated_timeline, -> (max_id, excluded_ids=[], page_no=nil) {
     
      filter_banned_statuses
      .where.not(id: excluded_ids)
      .where(local: false)
      .where(deleted_at: nil)
      .where(reply: false)
      .pagination(page_no, max_id)
    }

    scope :user_profile_timeline, -> (account_id, max_id = nil , page_no = nil ) {
      left_joins(:status_pins)
      .filter_block_mute_inactive_statuses(account_id)
      .where(account_id: account_id)
      .where(deleted_at: nil)
      .where(reply: false)
      .pin_statuses_fileter(max_id)
    }

    scope :pin_statuses_fileter, -> (max_id = nil) {
      if max_id.nil?
        joins(
          "LEFT JOIN status_pins on statuses.id = status_pins.status_id"
          ).reorder(
            Arel.sql('(case when status_pins.created_at is not null then 1 else 0 end) desc, statuses.id desc')
          ).limit(5)
      else 
        where(status_pins: { id: nil } )
              .filter_with_max_id(max_id)
              .order(id: :desc)
              .distinct
              .limit(5)
      end
    }


                                
    scope :my_community_timeline, -> (user_id, max_id, excluded_ids=[], page_no=nil) {
           
      joins(communities_statuses: :community)
      .filter_banned_statuses
      .joins(community_users: :community)
      .where.not(id: excluded_ids)
      .filter_statuses_without_rss
      .where.not(mammoth_communities: { slug: "breaking_news" })
      .where(community_users: { user_id: user_id })
      .where(deleted_at: nil)
      .filter_statuses_by_timeline_setting(user_id)
      .pagination(page_no, max_id)
    }
                                
    scope :following_timeline, -> (user_id, acc_id, max_id, page_no=nil) {
      filter_following_accounts(acc_id)
      .filter_banned_statuses
      .filter_statuses_by_timeline_setting(user_id)
      .filter_block_mute_inactive_statuses(acc_id)
      .where(reply: false)
      .pagination(page_no, max_id)
    }

    scope :pagination, ->( page_no = nil, max_id ) {
     
      if page_no.nil? || !page_no.present? || !page_no.is_a?(Integer)
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
    scope :filter_banned_statuses, -> { left_joins(:community_filter_statuses)
                                        .where(community_filter_statuses: { id: nil }) }
  end



  
end