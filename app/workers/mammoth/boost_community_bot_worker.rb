module Mammoth
  class BoostCommunityBotWorker
    include Sidekiq::Worker
    include FormattingHelper
    sidekiq_options retry: false, dead: true
    
    def perform(status_id, community_bot_account)
      post_url = get_post_url(status_id)
      bot_lamda_service = Mammoth::BoostLamdaCommunityBotService.new

      boost_status = bot_lamda_service.boost_status(community_bot_account, status_id, post_url)
      if boost_status["statusCode"] == 200
        return true 
      end
      false
    end

    private

    def get_post_url(status_id)
      status = Status.find(status_id)
      username = status.account.pretty_acct
      url = "https://newsmast.social/@#{username}/#{status_id}"
    end

  end 
end