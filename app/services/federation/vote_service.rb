# frozen_string_literal: true

module Federation
  class VoteService < BaseService
    def call(object, current_account, options = {})
      @options = options
      @activity_type = @options[:activity_type]&.to_sym
      @access_token = @options[:doorkeeper_token]&.token
      @login_user_domain = current_account.domain.nil? ? "newsmast.social" : current_account.domain
      @current_account = current_account
      @object = object.status
      search_federation!
      case @activity_type
      when :create
        create_vote!
      end
      call_third_party!
    end

    private 

    def create_vote!
      statuses = @response&.parsed_response["statuses"]
      poll = statuses[0]["poll"] if statuses
      poll_id = poll["id"] if poll
      
      @body = {
        choices: @options[:choices]
      }
      @action_url = "https://#{@login_user_domain}/api/v1/polls/#{poll_id}/votes"
    end

    def call_third_party!
      @response = third_party_service.call(url: @action_url, access_token: @access_token, http_method: @http_method || 'post', body: @body) if @action_url
    end

    def search_federation!
      raise ActiveRecord::RecordNotFound if @object.nil?
      raise ActiveRecord::RecordInvalid if @current_account.local?

      @response = search_service.call(object: @object, current_account: @current_account, access_token: @access_token)
    end

    def search_service
      @search_service ||= Federation::SearchService.new
    end


    def third_party_service
      @third_party_service ||= Federation::ThirdPartyService.new
    end
  end
end