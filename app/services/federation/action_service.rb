# frozen_string_literal: true

module Federation
  class ActionService < BaseService
    def call(object, current_account, options = {})
      
      @current_account = current_account
      @object_type = object.class.name
      @activity_type = options[:activity_type]&.to_sym
      @login_user_domain = current_account.domain
      @access_token = options[:doorkeeper_token]&.token
      @object = object 
      
      search_federation!
      federation_activity!

      raise ActiveRecord::RecordInvalid unless @response 

      return @response 
    rescue ActiveRecord::RecordInvalid
      unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      not_found
    rescue StandardError => e
      handle_error(e)
    end

    private

    def search_federation!
      raise ActiveRecord::RecordNotFound if @object.nil?

      raise ActiveRecord::RecordInvalid if @current_account.local?

      @response = search_service.call(object: @object, current_account: @current_account, access_token: @access_token)
    end

    def federation_activity!
      case @activity_type
      when :favourite
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/favourite" if status_id
      when :follow
        accounts = @response&.parsed_response["accounts"]
        accounts_id = accounts[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/accounts/#{accounts_id}/follow" if accounts_id
      when :reblog
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/reblog" if status_id
      when :create, :reply

      end
      call_third_party!
    end

    def call_third_party!
      @response = third_party_service.call(url: @action_url, access_token: @access_token, http_method: 'post') if @action_url
    end

    def search_service
      @search_service ||= Federation::SearchService.new
    end

    def third_party_service
      @third_party_service ||= Federation::ThirdPartyService.new
    end

    def handle_error(error)
      puts "Error occurred: #{error.message}"
    end
  end
end
