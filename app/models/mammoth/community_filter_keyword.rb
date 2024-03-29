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

    private

    def create_community_filter_statuses
      Mammoth::FilterKeyworkCreateWorker.perform_async(self.id, options = { action: 'create' })
    end

    def update_community_filter_statuses
      Mammoth::FilterKeyworkCreateWorker.perform_async(self.id, options = { action: 'update' })
    end

  end
end