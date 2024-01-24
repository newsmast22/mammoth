# frozen_string_literal: true

module Federation
  class SearchService < BaseService
    def call(options)
      @object            = options[:object]
      @type              = @object.class.name.to_sym
      @current_account   = options[:current_account]
      @limit             = 1
      @login_user_domain = @current_account.domain.nil? ? "newsmast.social" : @current_account.domain
      @access_token      = options[:access_token]

      prepare_search_url!
      call_search_api if @login_user_domain && @access_token
      @response
    rescue StandardError => e
      handle_error(e)
    end

    private

    def call_search_api
      puts "search url ===>> #{@search_url}"
      third_party_service.call(url: @search_url, access_token: @access_token, http_method: 'get')
    end

    def prepare_search_url!
      case @type
      when :Status
        @search_url = "https://#{@login_user_domain}/api/v2/search?q=#{URI.encode_www_form_component(@object.uri)}&resolve=true&limit=#{@limit}&type=statuses"
      when :Account
        @search_url = "https://#{@login_user_domain}/api/v2/search?q=@#{@object.username}@#{@object.domain}&resolve=true&limit=#{@limit}&type=accounts"
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
