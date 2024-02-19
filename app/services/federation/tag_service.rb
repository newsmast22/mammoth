# frozen_string_literal: true

module Federation
  class TagService < BaseService
    def call(object, current_account, options = {})
      initialize_variables(object, current_account, options)
      search_federation!
      federation_activity!
      return @response
    rescue Mastodon::UnexpectedResponseError
      render_error(503, "can not call remote api")
    rescue ActiveRecord::RecordNotFound
      render_error(404, "record not found for #{@object_type}")
    rescue ActiveRecord::RecordInvalid
      render_error(422, 'current user is a local user')
    end

    private

    def initialize_variables(object, current_account, options)
      @current_account = current_account
      @object_type = object.class.name
      @activity_type = options[:activity_type]&.to_sym
      @login_user_domain = current_account.domain
      @access_token = options[:doorkeeper_token]&.token
      @options = options
      @object = object
      @body = nil
    end

    def render_error(status, message)
      render json: { error: message }, status: status
    end

    def search_federation!
      raise ActiveRecord::RecordNotFound if @object.nil?
      raise ActiveRecord::RecordInvalid if @current_account.local?
      
      @response = search_service.call(object: @object, current_account: @current_account, access_token: @access_token)
    end

    def federation_activity!
      case @activity_type
      when :follow, :unfollow
        process_activity
      end
      call_third_party!
    end

    def process_activity
      hashtags = @response&.parsed_response["hashtags"]
    
      if hashtags.nil? || hashtags.empty?
        hashtag_name = @object.name
      else
        hashtag_name = hashtags.first["name"]
      end
    
      @action_url = "https://#{@login_user_domain}/api/v1/tags/#{hashtag_name}/#{@activity_type}" if hashtag_name
    end
    

    def call_third_party!
      @response = third_party_service.call(url: @action_url, access_token: @access_token, http_method: @http_method || 'post', body: @body) if @action_url
    end

    def search_service
      @search_service ||= Federation::SearchService.new
    end

    def third_party_service
      @third_party_service ||= Federation::ThirdPartyService.new
    end
  end
end
