module Mammoth
  class User < User
    self.table_name = 'users'
    
    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    has_many :user_communities , class_name: "Mammoth::UserCommunity"
    has_many :community_admins, class_name: "Mammoth::CommunityAdmin"
    belongs_to :wait_list, inverse_of: :user, optional: true


    scope :filter_with_words, ->(words) { joins(:account).where("LOWER(users.email) like '%#{words}%' OR LOWER(users.phone) like '%#{words}%' OR LOWER(accounts.username) like '%#{words}%' OR LOWER(accounts.display_name) like '%#{words}%'") }
    scope :filter_blocked_accounts,->(account_ids) {where.not(account_id: account_ids)}

  end
end