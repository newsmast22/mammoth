# frozen_string_literal: true

class Federation
  class ThirdPartyService < BaseService
    def call(url:, access_token:, body: {}, http_method: 'get')
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
      }

      @response = HTTParty.send(@http_method, @url, headers: headers, body: @body)

      handle_non_successful_response unless @response.success?
    end

    def handle_non_successful_response
      # Handle non-successful response, e.g., log the error or raise a custom exception
      puts "Non-successful HTTP response: #{@response.code}"
      @response = nil
    end

    def handle_error(error)
      puts "Error occurred: #{error.message}"
      @response = nil
    end
  end
end
