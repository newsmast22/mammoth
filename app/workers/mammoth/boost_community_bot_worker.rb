module Mammoth
  class BoostCommunityBotWorker
    include Sidekiq::Worker
    
    sidekiq_options queue: 'custom_bot_boosting', retry: false, dead: true
    
    def perform(community_id, status_id)      
      return false unless ENV['BOOST_COMMUNITY_BOT_ENABLED'] == 'true' && ENV['LOCAL_DOMAIN'] == "newsmast.social"

      puts "**********BoostCommunityBotWorker status_id: #{status_id} | community_id: #{community_id}"

      status = Mammoth::Status.find(status_id)

      puts "**********BoostCommunityBotWorker status: #{status.inspect}"

      Mammoth::CommunityBotService.new.call(community_id, status)
    end
  end 
end