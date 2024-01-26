# frozen_string_literal: true

module Federation
  class ActionService < BaseService
    def call(object, current_account, options = {})
      
      @current_account = current_account
      @object_type = object.class.name
      @activity_type = options[:activity_type]&.to_sym
      @login_user_domain = current_account.domain
      @access_token = options[:doorkeeper_token]&.token
      @options = options
      @object = object 
      @body = nil
  
      search_federation! unless @activity_type == :create
      federation_activity!

      return @response
    rescue Mastodon::UnexpectedResponseError
      render json: { error: "can not call remote api" }, status: 503
    rescue ActiveRecord::RecordNotFound
      render json: { error: "record not found for #{@object_type}" }, status: 404
    rescue ActiveRecord::RecordInvalid
      render json: { error: 'current user is local user' }, status: 422
    end

    private

    def search_federation!
      raise ActiveRecord::RecordNotFound if @object.nil?

      raise ActiveRecord::RecordInvalid if @current_account.local?

      @response = search_service.call(object: @object, current_account: @current_account, access_token: @access_token)
    end
    

    def federation_activity!
      case @activity_type
      when :follow
        accounts = @response&.parsed_response["accounts"]
        accounts_id = accounts[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/accounts/#{accounts_id}/follow" if accounts_id
      when :unfollow
        accounts = @response&.parsed_response["accounts"]
        accounts_id = accounts[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/accounts/#{accounts_id}/unfollow" if accounts_id
      when :mute 
        accounts = @response&.parsed_response["accounts"]
        accounts_id = accounts[0]["id"]
        @body = { duration: options[:duration], 
                  notifications: options[:notifications] }
        @action_url = "https://#{@login_user_domain}/api/v1/accounts/#{accounts_id}/mute" if accounts_id
      when :ummute 
        accounts = @response&.parsed_response["accounts"]
        accounts_id = accounts[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/accounts/#{accounts_id}/mute" if accounts_id
      when :delete
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}" if status_id
        @http_method = 'delete'
      when :favourite
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/favourite" if status_id
      when :unfavourite
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/unfavourite" if status_id
      when :reblog
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/reblog" if status_id
      when :unreblog
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/unreblog" if status_id
      when :pin
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/pin" if status_id
      when :unpin
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/unpin" if status_id
      when :bookmark 
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]

        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/bookmark" if status_id
      when :unbookmark
        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]

        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/unbookmark" if status_id
      when :reply

        statuses = @response&.parsed_response["statuses"]
        reply_to_id = statuses[0]["id"]
        
        @body = {
          in_reply_to_id: reply_to_id,
          language: @options[:language],
          media_ids: @options[:media_ids],
          poll: @options[:poll],
          sensitive: @options[:sensitive],
          spoiler_text: @options[:spoiler_text],
          status: @options[:status],
          visibility: @options[:visibility]
        }

        @action_url = "https://#{@login_user_domain}/api/v1/statuses" if reply_to_id
      when :create
        @body = {
          in_reply_to_id: nil,
          language: @options[:language],
          media_ids: @options[:media_ids],
          poll: @options[:poll],
          sensitive: @options[:sensitive],
          spoiler_text: @options[:spoiler_text],
          status: @options[:status],
          visibility: @options[:visibility]
        }

        @action_url = "https://#{@login_user_domain}/api/v1/statuses" 
      when :update

        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]

        @body = {
          in_reply_to_id: nil,
          language: @options[:language],
          media_ids: @options[:media_ids],
          poll: @options[:poll],
          sensitive: @options[:sensitive],
          spoiler_text: @options[:spoiler_text],
          status: @options[:status],
          visibility: @options[:visibility]
        }

        @http_method = 'put'
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}" if status_id
      when :reply_update

        statuses = @response&.parsed_response["statuses"]
        status_id = statuses[0]["id"]

        reply_object = Status.find(@options[:in_reply_to_id]) if @options[:in_reply_to_id]
        
        @reply_response = search_service.call(object: reply_object, current_account: @current_account, access_token: @access_token)
        
        reply_statuses = @reply_response&.parsed_response["statuses"]
        reply_status_id = reply_statuses[0]["id"]
        
        @body = {
          in_reply_to_id: reply_status_id,
          language: @options[:language],
          media_ids: @options[:media_ids],
          poll: @options[:poll],
          sensitive: @options[:sensitive],
          spoiler_text: @options[:spoiler_text],
          status: @options[:status],
          visibility: @options[:visibility]
        }

        @http_method = 'put'
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}" if status_id
      end
      call_third_party!
    end

    def call_third_party!
      @response = third_party_service.call(url: @action_url, access_token: @access_token, http_method: @http_method.nil? ? 'post' : @http_method, body: @body) if @action_url
    end

    def search_service
      @search_service ||= Federation::SearchService.new
    end

    def third_party_service
      @third_party_service ||= Federation::ThirdPartyService.new
    end
  end
end
