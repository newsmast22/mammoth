module Mammoth
  class CommunityFilterKeyword < ApplicationRecord
    belongs_to :community, class_name: "Mammoth::Community", optional: true
    belongs_to :account, class_name: "Account"
    has_many :community_filter_statuses , class_name: "Mammoth::CommunityFilterStatus", dependent: :destroy

    validates :keyword, uniqueness: { :if => :community_id?, :scope => :community_id}

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

      # 1.) Global keywords check from status's text
      create_status_manually_by_user(nil, status_id) 

      # 2.) Community keywords check from status's text 
      # Note: Check only is community_id is not nil
      create_status_manually_by_user(community_id, status_id) unless community_id.nil?

    end

    after_create :create_community_filter_statuses

    after_update :update_community_filter_statuses 

    private

    def create_community_filter_statuses

      json = {
        'community_id' => self.community_id,
        'is_status_create' => false,
        'status_id' => nil,
        'community_filter_keyword_id' => self.id,
        'community_filter_keyword_request' => "create"
      }
      community_statuses = Mammoth::CommunityFilterStatusesCreateWorker.perform_async(json)
    end

    def update_community_filter_statuses

      json = {
        'community_id' => self.community_id,
        'is_status_create' => false,
        'status_id' => nil,
        'community_filter_keyword_id' => self.id,
        'community_filter_keyword_request' => "update"
      }
      community_statuses = Mammoth::CommunityFilterStatusesCreateWorker.perform_async(json)
    end

    def create_status_manually_by_user(community_id, status_id)

      Mammoth::CommunityFilterKeyword.where(community_id: community_id).find_in_batches(batch_size: 100).each do |community_filter_keywords|
        community_filter_keywords.each do |community_filter_keyword|
          is_status_banned = Mammoth::Status.where("text ~* ? AND reply = false AND id = ?", "\\m#{community_filter_keyword.keyword}\\M", status_id).exists?
          if is_status_banned
            create_global_banned_statuses(community_filter_keyword,status_id)
          end
        end
      end
    end

    def create_global_banned_statuses(community_filter_Keyword,status_id)

      Mammoth::CommunityFilterStatus.where(
        status_id: status_id,
        community_filter_keyword_id: community_filter_Keyword.id
      ).first_or_create

    end

  end
end