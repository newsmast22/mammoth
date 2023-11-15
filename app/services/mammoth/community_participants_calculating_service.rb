module Mammoth
  class CommunityParticipantsCalculatingService < BaseService

    def call
      community_participants_calculator!
    end

    private

    def community_participants_calculator!
      Mammoth::Community.all.each do |community|
        account_data = Rails.cache.fetch("#{community.slug}-participants", expires_in: 1.hour) do
          Account.select('accounts.*')
            .joins('LEFT JOIN statuses ON accounts.id = statuses.account_id')
            .joins('LEFT JOIN mammoth_communities_statuses ON mammoth_communities_statuses.status_id = statuses.id')
            .joins('LEFT JOIN mammoth_communities ON mammoth_communities.id = mammoth_communities_statuses.community_id')
            .where.not(domain: nil)
            .where('mammoth_communities.id = ?', community.id)
            .group('accounts.id')
            .order("accounts.id desc")
        end
        community.update(participants_count: account_data.length) if account_data.present?
      end
    end
    
  end
end
