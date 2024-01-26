module Federation
  class StatusActionService < BaseService
    def call(object, current_account, options = {})
      initialize_variables(object, current_account, options)

      search_federation! unless @activity_type == :create
      federation_activity!

      return @response
    rescue Mastodon::UnexpectedResponseError
      render_error_response("can not call remote api", 503)
    rescue ActiveRecord::RecordNotFound
      render_error_response("record not found for #{@object_type}", 404)
    rescue ActiveRecord::RecordInvalid
      render_error_response('current user is local user', 422)
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

    def render_error_response(message, status)
      render json: { error: message }, status: status
    end

    def search_federation!
      raise ActiveRecord::RecordNotFound if @object.nil?
      raise ActiveRecord::RecordInvalid if @current_account.local?

      @response = search_service.call(object: @object, current_account: @current_account, access_token: @access_token)
    end

    def federation_activity!
      case @activity_type
      when :delete, :favourite, :unfavourite, :reblog, :unreblog, :pin, :unpin, :bookmark, :unbookmark
        handle_activity_type!
      when :update, :reply_update
        handle_reply_update_types!
      when :create 
        handle_create_types!
      when :reply 
        handle_reply_types!
      end
      call_third_party!
    end

    def handle_activity_type!
      statuses = @response&.parsed_response["statuses"]
      status_id = statuses[0]["id"] if statuses

      if ![:delete].include?(@activity_type)
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}/#{@activity_type}"
      else [:delete].include?(@activity_type)
        @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}"
        @http_method = 'delete'
      end
    end

    def handle_reply_types!
      statuses = @response&.parsed_response["statuses"]
      in_reply_to_id = statuses[0]["id"] if statuses

      @body = {
        in_reply_to_id: in_reply_to_id,
        language: @options[:language],
        media_ids: @options[:media_ids],
        poll: @options[:poll],
        sensitive: @options[:sensitive],
        spoiler_text: @options[:spoiler_text],
        status: @options[:status],
        visibility: @options[:visibility]
      }

      @action_url = "https://#{@login_user_domain}/api/v1/statuses" 
    end

    def handle_create_types!
     
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
    end

    def handle_reply_update_types!
      statuses = @response&.parsed_response["statuses"]
      status_id = statuses[0]["id"] if statuses
      @body = {
        in_reply_to_id: @options[:in_reply_to_id].present? ? get_in_reply_to_id : nil,
        language: @options[:language],
        media_ids: @options[:media_ids],
        poll: @options[:poll],
        sensitive: @options[:sensitive],
        spoiler_text: @options[:spoiler_text],
        status: @options[:status],
        visibility: @options[:visibility]
      }

      @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{status_id}"
      @http_method = 'put'
    end

    def get_in_reply_to_id
      reply_object = Status.find(@options[:in_reply_to_id])
      reply_response = search_service.call(object: reply_object, current_account: @current_account, access_token: @access_token)
      reply_statuses = reply_response&.parsed_response["statuses"]
      reply_statuses[0]["id"] if reply_statuses
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
