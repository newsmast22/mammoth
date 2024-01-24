# frozen_string_literal: true

class Federation::ThirdPartyService < BaseService
  def call(options = {})
    @url = options[:url]
    @token = options[:access_token]
    @body = options[:body]
    call_search_api
    @response
  end

  private 

  def call_search_api
    headers = {
      "Authorization" => "Bearer #{@token}"
    }
    @response = HTTParty.get(@url, headers: headers)
  end
end
