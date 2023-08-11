module Mammoth
  class CommunityFilterKeyword < ApplicationRecord
    belongs_to :community, class_name: "Mammoth::Community", optional: true
    belongs_to :account, class_name: "Account"
    has_many :community_filter_statuses , class_name: "Mammoth::CommunityFilterStatus", dependent: :destroy

    validates :keyword, uniqueness: { :if => :community_id?, :scope => :community_id}

    scope :by_community, ->(community_id) { where(community_id: community_id) }
    scope :ilike_any_keyword, ->(content_words) {
      where('LOWER(keyword) ILIKE ANY (ARRAY[?])', content_words.map { |word| "#{word.downcase}" })
    }

    def self.get_all_community_filter_keywords(account_id:, community_id:, max_id:)

      if max_id.present?
        query_string = "AND id < :max_id" if max_id.present?
      end

      community_filter_keywords = Mammoth::CommunityFilterKeyword.where("
        mammoth_community_filter_keywords.account_id = :account_id AND mammoth_community_filter_keywords.community_id = :community_id #{query_string}",
        account_id: account_id, community_id: community_id, max_id: max_id).order(id: :desc).limit(100)

    end

    def self.has_more_objects(account_id:,community_id:,community_filter_keyword_id:)
      Mammoth::CommunityFilterKeyword
      .where("
            mammoth_community_filter_keywords.account_id = :account_id
            AND mammoth_community_filter_keywords.community_id = :community_id
            AND id < :community_filter_keyword_id",
            account_id: account_id, community_id: community_id, community_filter_keyword_id: community_filter_keyword_id) 
       .exists?
    end

    def filter_statuses_by_keywords(community_id,status_id) 

      status = Mammoth::Status.where(id: status_id).last
      if status.present?
        content = status.text
        unless content.empty?

          # 1.) Global keywords check from status's text
          filter_statuses_by_global_keywords(content,status.id)

          # 2.) Community keywords check from status's text 
          # Note: Check only is community_id is not nil
          filter_statuses_by_community_keywords(content, status.id, community_id) unless community_id.nil?

        end
      end

    end

    def save_community_filter_keyword(community_id,status_id)
      status = Mammoth::Status.where(id: status_id).last
      if status.present?
        content = status.text
        unless content.empty?

        # Community keywords check from status's text 
        filter_statuses_by_community_keywords(content, status.id, community_id)
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

    def filter_statuses_by_global_keywords(content, status_id)

      content_words = content.downcase.split(/\W+/)
      @community_filter_Keywords = self.class.ilike_any_keyword(content_words)
      create_matched_keywords_status(status_id)

    end

    def filter_statuses_by_community_keywords(content, status_id, community_id)

      content_words = content.downcase.split(/\W+/)
      @community_filter_Keywords = self.class.ilike_any_keyword(content_words).by_community(community_id)
      create_matched_keywords_status(status_id)

    end

    def create_matched_keywords_status(status_id) 

      @community_filter_Keywords.each do |community_filter_Keyword|
        Mammoth::CommunityFilterStatus.where(
          status_id: status_id,
          community_filter_keyword_id: community_filter_Keyword.id
        ).first_or_create
      end

    end

  end
end