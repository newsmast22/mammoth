# frozen_string_literal: true

module Federation
  class MediaActionService < BaseService
    def call(object_id, current_account, options = {})
      @options = options
      @activity_type = @options[:activity_type]&.to_sym
      @access_token = @options[:doorkeeper_token]&.token
      @login_user_domain = current_account.domain
      @object_id = object_id

      case @activity_type
      when :create 
        create_media!
      when :update
        update_media!
      end
      call_third_party!
    end

    private 

    def update_media!
      @body = {
        file: @options[:file],
        thumbnail: @options[:thumbnail],
        description: @options[:description],
        focus: @options[:focus]
      }
      @http_method = 'put'
      @action_url = "https://#{@login_user_domain}/api/v1/media/#{@object_id}"
    end

    def create_media!
      @body = {
        file: @options[:file],
        thumbnail: @options[:thumbnail],
        description: @options[:description],
        focus: @options[:focus]
      }
      @action_url = "https://#{@login_user_domain}/api/v2/media"
    end

    def call_third_party!
      @response = third_party_service.call(url: @action_url, access_token: @access_token, http_method: @http_method || 'post', body: @body) if @action_url
    end

    def third_party_service
      @third_party_service ||= Federation::ThirdPartyService.new
    end
  end
end