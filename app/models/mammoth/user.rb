module Mammoth
  class User < User
    self.table_name = 'users'
    
    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    has_many :user_communities

    scope :filter_with_words, ->(words) { joins(:account).where("LOWER(users.email) like '%#{words}%' OR LOWER(users.phone) like '%#{words}%' OR LOWER(accounts.username) like '%#{words}%' OR LOWER(accounts.display_name) like '%#{words}%'") }

  end
end