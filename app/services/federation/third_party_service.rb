# frozen_string_literal: true

module Federation
  class ThirdPartyService < BaseService
    def call(options) 
      @url = options[:url]
      @token = options[:access_token]
      @http_method = options[:http_method].to_sym
      @body = options[:body]
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
      puts "Non-successful HTTP response: #{@response.code}"
      @response = nil
    end

    def handle_error(error)
      puts "Error occurred: #{error.message}"
      @response = nil
    end
  end
end
