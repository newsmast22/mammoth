# frozen_string_literal: true

class Federation::ActionService < BaseService
  def call(object, current_account, options = {})
    @current_account   = current_account
    @object_type = object.class.name
    @activity_type      = options[:activity_type].to_sym if options[:activity_type]
    @login_user_domain    = current_account.domain
    @access_token = options[:doorkeeper_token].token if options[:doorkeeper_token]
    search_federation!
    federation_activity!
  end

  private 

  def search_federation!
    if @object.nil?
      raise ActiveRecord::RecordNotFound, "#{@object_type} not found for object ID: #{object_id}"
    end
  
    if @current_account.local?
      raise ActiveRecord::RecordInvalid, "Login User Account is local."
    else
      if @object.local?
        @response = Federation::SearchService.new.call(@object, @current_account, access_token: @access_token)
      elsif !@object.local? && same_domain?(@object.uri)
        @response = @object
      elsif !@object.local? && !same_domain?(@object.uri)
        @response = Federation::SearchService.new.call(@object, @current_account, access_token: @access_token)
      end
    end
  end

  def federation_activity!
    case @activity_type
    when :favorite
      @status = @response&.statuses[0]
      @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{@status.id}/favourite"
    when :follow
      @account = @response&.accounts[0]
      @action_url = "https://#{@login_user_domain}/api/v1/accounts/#{@account.id}/follow"
    when :reblog
      @status = @response&.statuses[0]
      @action_url = "https://#{@login_user_domain}/api/v1/statuses/#{@status.id}/reblog"
    when :reply

    when :create
     
    end
    call_third_party!
  end

  def call_third_party!
    Federation::ThirdPartyService.new.call(url: @action_url, access_token: @access_token)
  end
  
  def same_domain?(url)
    uri    = Addressable::URI.parse(url).normalize
    return false unless uri.host

    domain = uri.host + (uri.port ? ":#{uri.port}" : '')

    domain == @current_account.domain
  end
end
