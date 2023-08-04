module Mammoth
  class CommunityFilterKeyword < ApplicationRecord
    belongs_to :community, class_name: "Mammoth::Community", optional: true
    belongs_to :account, class_name: "Account"
    has_many :community_filter_statuses , class_name: "Mammoth::CommunityFilterStatus"

    validates :keyword, uniqueness: { :if => :community_id?, :scope => :community_id}

    def self.get_all_community_filter_keywords(account_id:, community_id:, max_id:)

      if max_id.present?
        query_string = "AND id < :max_id" if max_id.present?
      end

      community_filter_keywords = Mammoth::CommunityFilterKeyword.where("
        mammoth_community_filter_keywords.account_id = :account_id AND mammoth_community_filter_keywords.community_id = :community_id #{query_string}",
        account_id: account_id, community_id: community_id, max_id: max_id).limit(100)

    end

    def filter_statuses_by_keywords(community_id,status_id) 

      status = Mammoth::Status.where(id: status_id).last
      if status.present?
        content = status.text

        unless content.empty?
          content_words = content.downcase.split(/\W+/)
          community_filter_Keywords = Mammoth::CommunityFilterKeyword.where('community_id = ? AND LOWER(keyword) ILIKE ANY (ARRAY[?])', community_id , content_words.map { |word| "#{word.downcase}" })

          community_filter_Keywords.each do |community_filter_Keyword|
            Mammoth::CommunityFilterStatus.where(
              status_id: status.id,
              community_filter_keyword_id: community_filter_Keyword.id
            ).first_or_create
          end
      end
      
      end
    end

    after_create :create_community_filter_statuses

    after_update :update_community_filter_statuses 

    private

    def create_community_filter_statuses

      json = {
        'community_id' => self.community_id,
        'is_status_create' => false,
        'status_id' => nil
      }

      community_statuses = Mammoth::CommunityFilterStatusesCreateWorker.perform_async(json)

    end

    def update_community_filter_statuses

      json = {
        'community_id' => self.community_id,
        'community_filter_keyword_id' => self.id
      }

      community_statuses = Mammoth::CommunityFilterStatusesUpdateWorker.perform_async(json)

    end

  end
end