module Mammoth
  class CommunityFilterKeyword < ApplicationRecord
    belongs_to :community, class_name: "Mammoth::Community", optional: true
    belongs_to :account, class_name: "Account"
    has_many :community_filter_statuses , class_name: "Mammoth::CommunityFilterStatus", dependent: :destroy

    validates :keyword, uniqueness: { :if => :community_id?, :scope => [:community_id, :is_filter_hashtag] }

    def self.get_all_community_filter_keywords(account_id:, community_id:, offset:, limit:)

      community_filter_keywords = Mammoth::CommunityFilterKeyword.where("
        mammoth_community_filter_keywords.account_id = :account_id AND mammoth_community_filter_keywords.community_id = :community_id",
        account_id: account_id, community_id: community_id).order(id: :desc).limit(limit).offset(offset)

    end

    after_create :create_community_filter_statuses

    after_update :update_community_filter_statuses

    def self.analyze_hashtag_matches(hashtags=[],is_filter_hashtag=true)
      # Loop through each hashtag and count matching records
      hashtag_counts ={}
      hashtags.each do |tag|
        count = Mammoth::CommunityFilterKeyword.where("LOWER(keyword) = LOWER(?)", tag).where(is_filter_hashtag: is_filter_hashtag).count
        hashtag_counts[tag] = count
      end
    
      # Output results
      puts "=== Hashtag Matching Records Summary ==="
      total_records = 0
    
      hashtag_counts.each do |tag, count|
        puts "#{tag}: #{count} records"
        total_records += count
      end
    
      puts "------------------------"
      puts "Total records found: #{total_records}"
    
      # Sort and display hashtags by number of matches (highest first)
      puts "\n=== Sorted by Count (Highest First) ==="
      hashtag_counts.sort_by { |_tag, count| -count }.each do |tag, count|
        puts "#{tag}: #{count} records" if count > 0
      end
        
      hashtag_counts
    end

    private

    def create_community_filter_statuses
      Mammoth::FilterKeyworkCreateWorker.perform_async(self.id, options = { action: 'create' })
    end

    def update_community_filter_statuses
      Mammoth::FilterKeyworkCreateWorker.perform_async(self.id, options = { action: 'update' })
    end

  end
end