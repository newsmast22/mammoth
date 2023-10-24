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
    scope :fetching_400_statuses, -> { where(created_at: 1.week.ago..).limit(200) }
    scope :included_by_recommend_status, ->(accounts) {
      where(id: accounts.flat_map { |account| account&.recommended_statuses }.uniq)
    }
    
    scope :included_by_community, ->(community) { 
      where(id: community.included_by_community_statuses)
    }  
    
    
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
        .where(communities_statuses: { community_id: [community.id, nil] }).limit(200)
    }

    scope :filter_statuses_with_not_belong_any_commu_admin, ->(community) {
      Mammoth::Status.left_joins(:communities_statuses)
        .filter_statuses_with_followed_acc_ids(community.get_community_admins)
        .where(communities_statuses: { community_id: nil }).limit(200)
    }
    
    scope :filter_statuses_with_current_user_logic, ->(account, community) {
      Mammoth::Status.left_joins(:communities_statuses)
        .filter_statuses_with_followed_acc_ids(account.id)
        .where(communities_statuses: { community_id: community.id }).limit(200)
    }

    scope :filter_recommended_community, -> {
      joins(communities_statuses: :community)
      .where(mammoth_communities: { is_recommended: true })
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
      joins(:account)
        .left_joins(account: :user)
        .where(user: { id: nil })
        .where.not(account: { domain: nil })
        .or(joins(:account)
          .left_joins(account: :user)
          .where.not(user: { id: nil })
          .where.not(user: { is_active: false })
          .where(account: { domain: nil }))
      .not_blocked(acc_ids)
      .not_muted(acc_ids)
    }

    scope :filter_block_inactive_statuses_by_acc_ids, -> (acc_ids) {
      joins(:account)
        .left_joins(account: :user)
        .where(user: { id: nil })
        .where.not(account: { domain: nil })
        .or(joins(:account)
          .left_joins(account: :user)
          .where.not(user: { id: nil })
          .where.not(user: { is_active: false })
          .where(account: { domain: nil }))
      .not_blocked(acc_ids)
    }

    scope :not_blocked, ->(acc_ids) {
      where.not(account_id: Block.where(account_id: acc_ids).pluck(:target_account_id))
      .where.not(account_id: Block.where(target_account_id: acc_ids).pluck(:account_id))
    }

    scope :not_muted, ->(acc_ids) {
      where.not(account_id: Mute.where(account_id: acc_ids).pluck(:target_account_id))
    }
    scope :not_belong_to_any_community, ->(community_id) {
      left_joins(:communities_statuses)
      .where(communities_statuses: {community_id: [nil, community_id] })
    }

    scope :belong_to_community, ->(community) {
      left_joins(:communities_statuses)
      .where(communities_statuses: {community_id: community.id})
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

    # scope :following_timeline_logic, ->(acc_id) {

    #   account = Mammoth::Account.find(acc_id)

    #   current_user_tag_ids = account.tag_follows.pluck(:tag_id).uniq

    #   left_joins(account: :follows)
    #     .left_joins(:status_tags)
    #     .where(follows: { account_id: account.id } )
    #     .or(where(status_tags: { tag_id: current_user_tag_ids })).limit(400)
    # }

    scope :following_timeline_logic, ->(acc_id) {
      account = Mammoth::Account.find(acc_id)
      current_user_tag_ids = account.tag_follows.pluck(:tag_id).uniq
    
      query_1 = Mammoth::Status.left_joins(:status_tags)
                                .where(status_tags: { tag_id: current_user_tag_ids }).limit(100).pluck(:id)
    
      query_2 = Mammoth::Status.joins(:account).left_joins(:follows)
                               .where(follows: { account_id: account.id }).limit(100).pluck(:id)
    
      status_ids = query_1.concat(query_2).uniq
      
      where(id: status_ids)
    }
   
    scope :following_timeline, ->(param) do
        following_timeline_logic(param.acc_id)
        .filter_banned_statuses_old
        .filter_statuses_by_timeline_setting(param.user_id)
        .where(reply: false)
        .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
        .pagination(param.page_no, param.max_id)
    end

    # Combined scope for user_community_recommended_timeline
    scope :user_community_recommended_timeline, ->(param) {
      
      admin_acc_ids = param.community.get_community_admins
      acc_ids = admin_acc_ids.push(param.account.id)

      fetching_400_statuses
      .filter_statuses_with_community_admin_logic(param.community, param.account)
      .or(filter_statuses_with_current_user_logic(param.account, param.community))
      .filter_statuses_by_community_timeline_setting(param.user.id)
      .filter_with_primary_timeline_logic(param.account, param.user, param.community)
      .where(deleted_at: nil)
      .where(reply: false)
      .where.not(account_id: param.account.id)
      .filter_banned_statuses_old
      .filter_block_mute_inactive_statuses_by_acc_ids(acc_ids)
      .pagination(param.page_no, param.max_id)

    }


    scope :user_community_all_timeline, ->(param) {

      admin_acc_ids = param.community.get_community_admins
      acc_ids = admin_acc_ids.push(param.account.id)

      fetching_400_statuses
      .left_joins(:communities_statuses)
      .where(communities_statuses: { community_id: param.community.id })
      .or(filter_statuses_with_not_belong_any_commu_admin(param.community))
      .filter_statuses_by_community_timeline_setting(param.user.id)
      .filter_with_primary_timeline_logic(param.account, param.user, param.community)
      .where(reply: false, deleted_at: nil)
      .filter_banned_statuses_old
      .filter_block_mute_inactive_statuses_by_acc_ids(acc_ids)
      .pagination(param.page_no, param.max_id)
    }
                       
    scope :all_timeline, -> (param) {

      fetching_400_statuses
      .joins(communities_statuses: :community)
      .filter_banned_statuses_old
      .where.not(mammoth_communities: { slug: "breaking_news" })
      .filter_statuses_without_rss
      .where(deleted_at: nil)
      .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
      .pagination(param.page_no, param.max_id)
    }

    scope :all_timeline_logic, -> {
      joins(communities_statuses: :community)
      .where.not(mammoth_communities: { slug: "breaking_news" })
    }
  
    scope :newsmast_timeline, -> (param) {
      fetching_400_statuses
      .filter_banned_statuses_old
      .where(local: true, deleted_at: nil, reply: false, is_rss_content: false)
      .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
      .pagination(param.page_no, param.max_id)
    }

    scope :get_newsmast_statuses_lates_400, -> {
      where(local: true, deleted_at: nil, is_rss_content: false)
      .order(id: :desc).limit(400)
    }

    scope :federated_timeline, -> (param) {
     
      fetching_400_statuses
      .filter_banned_statuses_old
      .where(local: false, deleted_at: nil, reply: false)
      .filter_block_mute_inactive_statuses_by_acc_ids(param.acc_id)
      .pagination(param.page_no, param.max_id)
    }

    scope :get_federated_statuses_lates_400, -> {
      where(local: false, deleted_at: nil)
      .order(id: :desc).limit(400)
    }

    scope :user_profile_timeline, -> (account_id, profile_id, max_id = nil , page_no = nil ) {

      left_joins(:status_pins)
      .where(deleted_at: nil, reply: false, account_id: profile_id)
      .filter_block_inactive_statuses_by_acc_ids(account_id)
      .pin_statuses_fileter(max_id)
    }

    scope :my_community_timeline, -> (param) {

      acc_ids = Mammoth::Account.get_community_admins_by_my_communties(param.acc_id).pluck(:id)
      acc_ids = acc_ids.push(param.acc_id)

      fetching_400_statuses
      .joins(communities_statuses: :community)
      .joins(community_users: :community)
      .filter_statuses_without_rss
      .where.not(mammoth_communities: { slug: "breaking_news" })
      .where(community_users: { user_id: param.user_id })
      .filter_banned_statuses_old
      .where(deleted_at: nil)
      .filter_statuses_by_timeline_setting(param.user_id)
      .filter_block_mute_inactive_statuses_by_acc_ids(acc_ids)
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
      where(reply: false, community_feed_id: nil, group_id: nil)
    }

    scope :inactive_account_ids, -> {
        joins(account: :user)
        .where(users: { is_active: false} )
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
      joins(:account).where(account: { country: country_alpha2_name })
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

    scope :filter_banned_statuses_old, -> { left_joins(:community_filter_statuses).where(community_filter_statuses: { id: nil }) }

    scope :filter_banned_statuses, -> { Rails.cache.fetch("filter_statuses_ids") { where.not(id: excluded_from_timeline_account_ids) } }

    def blocked_by_community_admin?
      return false unless self.communities.present?
    
      admin_ids = get_community_admins
      blocked = Block.where(account_id: account_id, target_account_id: admin_ids)
                    .or(Block.where(account_id: admin_ids, target_account_id: account_id))
      blocked.any?
    end

    scope :excluded_from_timeline_account_ids, -> {
      Rails.cache.fetch("bunned_statuses_ids") { joins(:community_filter_statuses).pluck(:status_id) }
    }

    def is_recommended_community?
      Mammoth::Status.joins(communities_statuses: :community)
      .where(community: { is_recommended: true }, id: self.id).any?
    end

    def another_recommended_community?(community_id)
      Mammoth::Status.joins(communities_statuses: :community)
      .where(community: { is_recommended: true }, id: self.id)
      .where.not(community: { id: community_id }).any?
    end

    def is_bot_acc?
      Mammoth::Status.joins(account: :users)
      .where(users: { email: "posts@#{ENV['LOCAL_DOMAIN']}" }, id: self.id).any?
    end
  
    def get_community_admins
      community_admins = self.communities.get_community_admins
      community_admins.concat(self.reblog&.communities.get_community_admins) if self.reblog?
      community_admins.uniq
    end

    def get_recommended_communities
      Mammoth::Community.joins(community_statuses: :community)
      .where(community: { is_recommended: true }, community_statuses: { status_id: self.id })
    end

    def is_valid_my_community?
      Mammoth::Status.joins(communities_statuses: :community)
      .where.not(community: { slug: "breaking_news" })
      .where(reply: false, community_feed_id: nil, group_id: nil, id: self.id).any?
    end
                                
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

    def self.get_statues_by_commu_slug(community_slug)
      Mammoth::Status
        .left_joins(communities_statuses: :community)
        .where(community: { slug: [community_slug, nil] })
    end

    def is_followed_other_admin(community)
      !get_admins_from_follow.empty? && community.is_contain_admin?(self.get_admins_from_follow.pluck(:id))
    end
    
    def get_admins_from_follow
      Mammoth::Account.where(id: self.account.get_followed_admins)
    end

    def belong_to_other?(community_id)
      Mammoth::Status
        .left_joins(:communities_statuses)
        .where(communities_statuses: { community_id: [community_id, nil] }, id: self.id)
        .none?
    end    
  end
end