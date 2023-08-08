module Mammoth
  class User < User
    self.table_name = 'users'
    
    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    has_many :user_communities , class_name: "Mammoth::UserCommunity"
    has_many :community_admins, class_name: "Mammoth::CommunityAdmin"
    belongs_to :wait_list, inverse_of: :user, optional: true


    scope :filter_with_words, ->(words) { joins(:account).where("LOWER(users.email) like '%#{words}%' OR LOWER(users.phone) like '%#{words}%' OR LOWER(accounts.username) like '%#{words}%' OR LOWER(accounts.display_name) like '%#{words}%'") }
    scope :filter_blocked_accounts,->(account_ids) {where.not(account_id: account_ids)}

    def self.selected_filters_for_user(user_id)
      select(
        Arel.sql("(selected_filters->'source_filter'->'selected_contributor_role') AS selected_contributor_roles"),
        Arel.sql("(selected_filters->'source_filter'->'selected_voices') AS selected_voices"),
        Arel.sql("(selected_filters->'source_filter'->'selected_media') AS selected_media"),
        Arel.sql("(selected_filters->'location_filter'->'selected_countries') AS selected_countries"),
        Arel.sql("(selected_filters->'communities_filter'->'selected_communities') AS selected_communities")
      )
      .where(user_id: user_id)
      .first
    end
  end
end