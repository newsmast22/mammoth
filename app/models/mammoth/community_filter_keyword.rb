module Mammoth
  class CommunityFilterKeyword < ApplicationRecord
    belongs_to :community, class_name: "Mammoth::Community", optional: true
    belongs_to :account, class_name: "Account"

    #validates :keyword, uniqueness: { scope: Proc.new { :community_id if community_id.present? }}
    validates :keyword, uniqueness: { :if => :community_id?, :scope => :community_id}

    def self.get_all_community_filter_keywords(account_id:, community_id:, max_id:)

      if max_id.present?
        query_string = "AND id < :max_id" if max_id.present?
      end

      community_filter_keywords = Mammoth::CommunityFilterKeyword.where("
        mammoth_community_filter_keywords.account_id = :account_id AND mammoth_community_filter_keywords.community_id = :community_id #{query_string}",
        account_id: account_id, community_id: community_id, max_id: max_id)

    end

  end
end