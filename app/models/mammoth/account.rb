module Mammoth
  class Account < Account
    include Redisable
    
    self.table_name = 'accounts'
    belongs_to :media, class_name: "Mammoth::Media",  optional: true
    belongs_to :voice, class_name: "Mammoth::Voice",  optional: true
    belongs_to :contributor_role, class_name: "Mammoth::ContributorRole",  optional: true
    belongs_to :subtitle, class_name: "Mammoth::Subtitle",  optional: true

    has_many :follows, foreign_key: 'target_account_id'
    has_many :followed_accounts, through: :follows, source: :target_account

    has_many :blocks, foreign_key: 'account_id'
    has_many :blocked_accounts, through: :blocks, source: :target_account

    has_many :mutes
    has_many :muted_accounts, through: :mutes, source: :target_account
    has_many :users
    has_many :statuses

    has_many :tag_follows
    has_many :tags, through: :tag_follows
    

    scope :filter_timeline_with_countries,->(country_alpah2_name) {where(country: country_alpah2_name)}
    scope :filter_timeline_with_contributor_role,->(id) {where( "about_me_title_option_ids && ARRAY[?]::integer[]",id)}
    scope :filter_timeline_with_voice,->(id) {where("about_me_title_option_ids && ARRAY[?]::integer[] ", id)}
    scope :filter_timeline_with_media,->(id) {where("about_me_title_option_ids && ARRAY[?]::integer[] ", id)}

    scope :get_community_admins_by_my_communties, ->(acc_id) {
        community_ids = Mammoth::Community.get_my_communities(acc_id).pluck(:id)
        joins(users: :community_admins)
              .where(community_admins: {community_id: community_ids})
    }

    scope :following_accouts, -> (account_id, current_account_id, offset, limit){
            joins("INNER JOIN follows ON accounts.id = follows.target_account_id")
            .where("follows.account_id = ? AND accounts.id != ?",account_id, current_account_id)
            .order("accounts.id DESC")
            .limit(limit).offset(offset)
          }

    scope :follower_accouts, -> (account_id, current_account_id, offset, limit){
            joins("INNER JOIN follows ON accounts.id = follows.account_id")
            .where("follows.target_account_id = ? AND accounts.id != ?",account_id, current_account_id)
            .order("accounts.id DESC")
            .limit(limit).offset(offset)
          }

    scope :for_local_distribution, -> {
        joins(:user)
          .where(domain: nil)
          .where('users.current_sign_in_at > ?', User::ACTIVE_DURATION.ago)
      }

    scope :get_communities_follower_by_commu_id, ->(community_ids) {
      joins(users: :user_communities)
        .where(domain: nil, user_communities: {community_id: community_ids})
        .where('users.current_sign_in_at > ?', User::ACTIVE_DURATION.ago)
    }

    def get_owned_communities
      Mammoth::Community.joins(community_admins: { user: :account })
        .where(account: {id: self.id})
    end

    def is_community_admin?
      get_owned_communities.any?
    end

    def is_joined_community?(community_id)
      Mammoth::UserCommunity.where(user_id: self.user.id, community_id: community_id).any?
    end

    def get_followed_admins
      Follow.where(account_id: get_all_community_admins.pluck(:id), target_account_id: self.id).pluck(:account_id)
    end

    def get_followed_private_admins
      Follow.where(account_id: get_private_community_admins.pluck(:id), target_account_id: self.id).pluck(:account_id)
    end

    def get_joined_communities
      Mammoth::Community.joins(:community_users).where(community_users: { user_id: self.user.id })
    end

    def get_all_community_admins
      Mammoth::Account.joins(users: :community_admins)
    end

    def get_private_community_admins 
      private_community_slug = ENV.fetch('PRIVATE_COMMUNITY', nil)
      private_community_account_email = ENV.fetch('PRIVATE_COMMUNITY_ACCOUNT_EMAIL', nil)
  
      return [] if private_community_slug.blank? || private_community_account_email.blank?

      Mammoth::Account
        .joins(users: {community_admins: :community})
        .where(users: { email: private_community_account_email })
        .where(community: {slug: private_community_slug})

    end

    def recommended_statuses
      redis.zrange("feed:recommended:#{id}", 0, -1, with_scores: false)
    end

  end
end