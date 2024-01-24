# frozen_string_literal: true

class Federation
  class ThirdPartyService < BaseService
    def call(url:, access_token:, body: nil, http_method: 'get')
      @url = url
      @token = access_token
      @http_method = http_method.to_sym
      @body = body
      call_search_api
      @response
    rescue StandardError => e
      handle_error(e)
    end

    private

    def call_search_api
      headers = {
        "Authorization" => "Bearer #{@token}"
      }.freeze

      @response = HTTParty.get(@url, headers: headers)
    end

    def handle_error(error)
      puts "Error occurred: #{error.message}"
      @response = nil
    end
  end
end
