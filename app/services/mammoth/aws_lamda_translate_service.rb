module Mammoth
  class AwsLamdaTranslateService 
    require 'httparty'
  
      def initialize  
          @base_url = ENV['TRANSLATE_URL']
          @api_key = ENV['TRANSLATE_API_KEY']
      end
      
      def translate_text(text, is_mastodon)

      unless is_mastodon
        # Check if the string contains any HTML tags
        contains_html_tags = /<("[^"]*"|'[^']*'|[^'">])*>/.match?(text)

        if contains_html_tags
          text = PlainTextFormatter.new(text, false).to_s
        end
      end

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