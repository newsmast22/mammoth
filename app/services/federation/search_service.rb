# frozen_string_literal: true

class Federation
  class SearchService < BaseService
    def call(object:, current_account:, limit: 1, options: {})
      @object            = object
      @type              = @object.class.name.to_sym
      @current_account   = current_account
      @limit             = limit
      @login_user_domain = current_account.domain
      @access_token      = options[:access_token]
      @host_address      = "https://#{@login_user_domain}/api/v2/search?".freeze

      prepare_search_url!
      call_search_api if @domain && @access_token

      @response
    rescue StandardError => e
      handle_error(e)
    end

    private

    def call_search_api
      third_party_service.call(url: @search_url, access_token: @access_token)
    end

    def prepare_search_url!
      case @type
      when :Status
        @search_url = "#{@host_address}?q=#{URI.encode_www_form_component(@object.uri)}&resolve=true&limit=#{@limit}&type=statuses"
      when :Account
        @search_url = "#{@host_address}?q=@#{@object.username}@#{@object.domain}&resolve=true&limit=#{@limit}&type=accounts"
      end
    end

    def third_party_service
      @third_party_service ||= Federation::ThirdPartyService.new
    end

    def handle_error(error)
      puts "Error occurred: #{error.message}"
      @response = nil
    end
  end
end
