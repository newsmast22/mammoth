module Mammoth
  class AwsLamdaTranslateService 
    require 'httparty'
  
      def initialize  
          @base_url = ENV['TRANSLATE_URL']
          @api_key = ENV['TRANSLATE_API_KEY']
      end
      
      def translate_text(text)
        HTTParty.post(@base_url, 
          :body => {
            "prompt": text
          }.to_json,
          :headers => {'Content-Type' => 'application/json',
                      "x-api-key" => @api_key
                      }
        )
      end
  end
end