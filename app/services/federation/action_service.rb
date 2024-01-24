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
        @status = @response&.statuses&.first
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{@status.id}/favourite" if @status
      when :follow
        @account = @response&.accounts&.first
        @action_url = "https://#{@login_user_domain}/api/v1/accounts/#{@account.id}/follow" if @account
      when :reblog
        @status = @response&.statuses&.first
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{@status.id}/reblog" if @status
      when :reply

      when :create

      end
      call_third_party!
    end

    def call_third_party!
      third_party_service.call(url: @action_url, access_token: @access_token, http_method: 'post') if @action_url
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
