module Mammoth
  class BoostLamdaCommunityBotService 
  require 'httparty'
  
    def initialize  
        @base_url = ENV['BOOST_COMMUNITY_BOT_URL']
        @api_key = ENV['BOOST_COMMUNITY_BOT_API_KEY']
    end
    
    def boost_status(post_bot_account, post_id, post_url)

      result = HTTParty.post(@base_url, 
        :body => { 
          "body": {
            "post_bot": post_bot_account,
            "post_id": post_id,
            "post_url": post_url
          }  
        }.to_json,
        :headers => {'Content-Type' => 'application/json',
                    "x-api-key" => @api_key
                    }
      )
      return result
    end
  
  end
end