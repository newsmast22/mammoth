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
        "Authorization" => "Bearer 1SntJvOkChG2iaEG9GwQXg5eyQdm9SEmv1UZurjS1tY"
      }

      case @http_method
      when :get 
        @response = HTTParty.get(@url, headers: headers)
      when :post 
        @response = HTTParty.post(@url, headers: headers, body: @body)
      when :put 
        @response = HTTParty.put(@url, headers: headers, body: @body)
      when :delete 
        @response = HTTParty.delete(@url, headers: headers, body: @body)
      when :patch 
        @response = HTTParty.patch(@url, headers: headers, body: @body)
      end
      raise Mastodon::UnexpectedResponseError, @response unless response_successful?(@response) || response_error_unsalvageable?(@response)
    end
  end
end
