module Mammoth
  class CommunityFilterKeyword < ApplicationRecord
    belongs_to :community, class_name: "Mammoth::Community", optional: true
    belongs_to :account, class_name: "Account"
    has_many :community_filter_statuses , class_name: "Mammoth::CommunityFilterStatus", dependent: :destroy

    validates :keyword, uniqueness: { :if => :community_id?, :scope => [:community_id, :is_filter_hashtag] }

    def is_banned?(status_id, keyword)
      is_status_banned = false
      text = Mammoth::Status.where("id = ?", status_id).last.text

      return is_status_banned = false if text.blank?
      
      # Case : 1 ) Filter keyword is only one word?
      if one_word?(keyword.downcase)
        is_status_banned = text.downcase.split(' ').include?(keyword.downcase)

      # Case : 2 ) Filter keyword is two or more words?  
      elsif keyword_matches_string(keyword.downcase, text.downcase)
        is_status_banned = true
      end

      return is_status_banned
    end


    def self.get_all_community_filter_keywords(account_id:, community_id:, offset:, limit:)

      community_filter_keywords = Mammoth::CommunityFilterKeyword.where("
        mammoth_community_filter_keywords.account_id = :account_id AND mammoth_community_filter_keywords.community_id = :community_id",
        account_id: account_id, community_id: community_id).order(id: :desc).limit(limit).offset(offset)

    end

    after_create :create_community_filter_statuses

    after_update :update_community_filter_statuses 

    private

    def create_community_filter_statuses

      json = {
        'community_id' => self.community_id,
        'is_status_create' => "non",
        'status_id' => nil,
        'community_filter_keyword_id' => self.id,
        'community_filter_keyword_request' => "create"
      }
      community_statuses = Mammoth::CommunityFilterStatusesCreateWorker.perform_async(json)
    end

    def update_community_filter_statuses

      json = {
        'community_id' => self.community_id,
        'is_status_create' => "non",
        'status_id' => nil,
        'community_filter_keyword_id' => self.id,
        'community_filter_keyword_request' => "update"
      }
      community_statuses = Mammoth::CommunityFilterStatusesCreateWorker.perform_async(json)
    end

    def keyword_matches_string(keyword, string)
      # Escape special characters in the keyword for regex matching
      escaped_keyword = Regexp.escape(keyword)
    
      # Create a regular expression pattern with word boundaries
      pattern = /\b#{escaped_keyword}\b/i # Use 'i' for case-insensitive matching
    
      # Check if the pattern matches anywhere in the string
      match = string.match(pattern)
    
      # Return true if there's a match, false otherwise
      !match.nil?
    end

    def one_word?(string)
      string.split(/\s+/).length == 1
    end

  end
end