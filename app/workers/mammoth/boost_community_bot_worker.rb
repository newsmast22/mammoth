module Mammoth
  class BoostCommunityBotWorker
    include Sidekiq::Worker
    
    sidekiq_options queue: 'custom_bot_boosting', retry: false, dead: true
    
    def perform(community_id, status_id)      
      puts "**********BoostCommunityBotWorker status_id: #{status_id} | community_id: #{community_id}"
      Mammoth::CommunityBotService.new.call(community_id, status_id)
    end
  end 
end