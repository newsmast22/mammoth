# frozen_string_literal: true

module Federation
  class ThirdPartyService < BaseService
    include JsonLdHelper

    def call(options) 
      @url = options[:url]
      @token = options[:access_token]
      @http_method = options[:http_method].to_sym
      @body = options[:body]
      call_search_api
      @response
    end

    private

    def call_search_api
      headers = {
        "Authorization" => "Bearer FDRQgKCB6LT90d2TxG5JG6GruwNooAVDNO8tIjm_XIc"
      }

      case @http_method
      when :get 
        @response = HTTParty.get(@url, headers: headers)
      when :post 
        @response = HTTParty.post(@url, headers: headers, body: @body)
      when :put 
      end
      raise Mastodon::UnexpectedResponseError, @response unless response_successful?(@response) || response_error_unsalvageable?(@response)
    end
  end
end
