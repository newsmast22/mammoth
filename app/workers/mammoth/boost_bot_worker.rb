module Mammoth
  class BoostBotWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'custom_bot_boosting', retry: false, dead: true
    
    def perform(status_id)
      bot_lamda_service = Mammoth::BoostLamdaBotService.new
      boost_status = bot_lamda_service.boost_status(status_id)
      if boost_status["statusCode"] == 200
        return true 
      end
      false
    end

  end 
end