module Mammoth
  class BoostCommunityBotWorker
    include Sidekiq::Worker
    include FormattingHelper
    sidekiq_options queue: 'custom_bot_boosting', retry: false, dead: true
    
    def perform(community_id, status_id)      
      return false unless ENV['BOOST_COMMUNITY_BOT_ENABLED'] == 'true' && ENV['LOCAL_DOMAIN'] == "newsmast.social"

      puts "BoostCommunityBotWorker status_id: #{status_id} | community_id: #{community_id}"
      Mammoth::Status.reload
      @status = Mammoth::Status.find(status_id)

      if community_id.nil?
        boost_for_all_community
      else
        boost_by_community_bot(community_id)
      end

    end

    private

      def boost_for_all_community
        # Looping community to fetch followed accounts by community admin
        @status.get_admins_from_follow.each do |community_admin|
          communities = Mammoth::Account.find(community_admin.id).get_owned_communities
          # Looping community
          communities.each do |community|
            boost_by_community_bot(community.id)
          end
        end
      end

      def boost_by_community_bot(community_id)
        community_bot_account = get_community_bot_account(community_id)
        return false if community_bot_account.nil? || @status.banned? || is_blocked_by_admins?(community_id, @status.account_id)

        post_url = get_post_url
        bot_lamda_service = Mammoth::BoostLamdaCommunityBotService.new

        boost_status = bot_lamda_service.boost_status(community_bot_account, @status.id, post_url)
        return true if boost_status["statusCode"] == 200
        false
      end

      def get_post_url
        username = @status.account.pretty_acct
        url = "https://newsmast.social/@#{username}/#{@status.id}"
      end

      def get_community_bot_account(community_id)
        Mammoth::Community.where(id: community_id).last&.bot_account
      end

      def is_blocked_by_admins?(community_id, account_id)
        target_account_ids = (
                              Block
                              .where(account_id: Mammoth::Account
                              .joins(users: :community_admins)
                              .where(community_admins: { community_id: community_id}, users: { role_id: 4 })
                              .pluck(:id))
                              .pluck(:target_account_id) + Mute
                              .where(account_id: Mammoth::Account
                              .joins(users: :community_admins)
                              .where(community_admins: { community_id: community_id}, users: { role_id: 4 })
                              .pluck(:id))
                              .pluck(:target_account_id)
                              ).uniq
        
        return true if target_account_ids.include?(account_id.to_i)
        false
      end

  end 
end