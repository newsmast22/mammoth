module Mammoth
  class BoostLamdaBotService
  require 'httparty'

    def initialize
        @base_url = ENV['BOOST_BOT_URL']
        @api_key = ENV['BOOST_BOT_API_KEY']
    end

    def boost_status(status_id)
      status = Status.find_by(id: status_id)
      close_group = ''
      if status
        owner_email = status.account.user.email
        if owner_email == ENV['PRIVATE_COMMUNITY_ACCOUNT_EMAIL']
          close_group = "@#{ENV['PRIVATE_COMMUNITY_ACCOUNT_EMAIL']}"
        end
      end
      res = HTTParty.post(@base_url,
        :body => {
          "body": {
              "post_id": status_id.to_s,
              "close_group": close_group
          }
        }.to_json,
        :headers => {'Content-Type' => 'application/json',
                    "x-api-key" => @api_key
                    }
      )
    end

  end
end
