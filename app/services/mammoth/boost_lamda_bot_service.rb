module Mammoth
  class BoostLamdaBotService 
  require 'httparty'
  
    def initialize  
        @base_url = ENV['BOOST_BOT_URL']
        @api_key = ENV['BOOST_BOT_API_KEY']
    end
    
    def boost_status(status_id)
      res = HTTParty.post(@base_url, 
        :body => {
          "body": {
              "post_id": status_id.to_s
          }
        }.to_json,
        :headers => {'Content-Type' => 'application/json',
                    "x-api-key" => @api_key
                    }
      )
    end
  
  end
end