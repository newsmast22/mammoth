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

      puts "url : #{@url} http_method : #{@http_method}" 
      puts "headers : #{@headers}"
      puts "token : #{@token}"
      
      case @http_method
      when :get 
        @response = HTTParty.get(@url, headers: headers)
      when :post 
        @response = HTTParty.post(@url, headers: headers, body: @body)
      when :put 
      end

      puts "api response : #{@response}"

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
