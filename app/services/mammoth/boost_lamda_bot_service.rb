module Mammoth
  class BoostLamdaBotService
    require 'httparty'

    def initialize
      @base_url = ENV['BOOST_BOT_URL']
      @api_key = ENV['BOOST_BOT_API_KEY']
    end

    def boost_status(status_id)
      status = Status.find_by(id: status_id)
      return unless status

      close_group = determine_close_group(status)

      response = send_boost_request(status_id, close_group)
    
      handle_response(response)
      
    end

    private

    def determine_close_group(status)
      if status.account.follow_private_community? && status.mentioned_private_community_account?
        "@#{ENV['PRIVATE_COMMUNITY_ACCOUNT_EMAIL']}"
      elsif status.account.follow_presidentnews_account? && status.mentioned_president_news_account?
        "@#{ENV['PRESIDENTNEWS_ACCOUNT_EMAIL']}"
      else
        ""
      end
    end

    def send_boost_request(status_id, close_group)
      HTTParty.post(
        @base_url,
        body: {
          body: {
            post_id: status_id.to_s,
            close_group: close_group
          }
        }.to_json,
        headers: default_headers
      )
    end

    def handle_response(response)
      raise "Boost request failed with status: #{response.code}" unless response.success?
    end

    def default_headers
      {
        'Content-Type' => 'application/json',
        'x-api-key' => @api_key
      }
    end

  end
end