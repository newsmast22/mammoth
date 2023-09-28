class Mammoth::FediverseLoginService < BaseService

  # Login with other fediverse instances or servers
  # doorkeeper_token application object
  # @param [Hash] options
  # @option [String] :code
  # @option [String] :redirect_uris
  # @option [String] :client_id
  # @option [String] :client_secret
  # @option [String] :instance
  # @return [access_token & login essential data]
  require 'net/http'

  def call(options = {}, doorkeeper_token)
    
    uri = URI("https://#{options[:instance]}/oauth/token")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(
      'client_id' => options[:client_id],
      'client_secret' => options[:client_secret],
      'code' => options[:code],
      'grant_type' => 'authorization_code',
      'redirect_uri' => options[:redirect_uris]
    )

    response = http.request(request)

    if response.code.to_i == 200
      token_data = JSON.parse(response.body)

      # The token_data should contain an access token that you can use to make authenticated API requests.
      access_token = token_data['access_token']
      create_or_fetch_user_by_token(options, access_token, doorkeeper_token)

    else

      result = {
        data: {
          error: "Token expired"
        },
        status_code: 422
      }
      return result

    end
  end

  private 

  def create_or_fetch_user_by_token(options = {}, access_token, doorkeeper_token)

    # Fetch user object by access_token
    api_uri = URI("https://#{options[:instance]}/api/v1/accounts/verify_credentials")

    http = Net::HTTP.new(api_uri.host, api_uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(api_uri.path)
    request['Authorization'] = "Bearer #{access_token}"
    response = http.request(request)
    user_data = JSON.parse(response.body)

    @account = Account.find_by(domain: options[:instance], username: user_data["username"])
    @user = User.find_by(account_id: @account.try(:id).nil? ? 0 : @account.id)

    if @user.nil?
      @user = User.new()
      @user.created_by_application= doorkeeper_token.application
      @user.sign_up_ip= " "
      @user.email= "" 
      @user.password= nil 
      @user.agreement= true
      @user.locale= "en"
      @user.password_confirmation= nil 
      if @account.nil?
        @user.account_attributes = {
          display_name: user_data["display_name"],
          username: user_data["username"],
          domain: options[:instance],
          note: user_data["note"],
          uri: user_data["uri"],
          url: user_data["url"],
          fields: user_data["fields"],
          discoverable: user_data["discoverable"],
          hide_collections: user_data["hide_collections"],
          #avatar: image_exitst(user_data["avatar"]) === true ? File.open(set_image(user_data["avatar"], user_data["id"], "avatar")) : nil,
          #header: image_exitst(user_data["header"]) === true ? File.open(set_image(user_data["header"], user_data["id"], "header")) : nil,
        }
      else 
        @user.account_id = @account.id
      end
      @user.invite_request_attributes = { text:user_data["reason"] }
      @user.wait_list_id = nil
      @user.step = "dob"
      @user.otp_code = nil
      @user.confirmed_at = Time.now.utc
      @user.save(validate: false)

      # Delete images (avatar/header) in tmp folders
      #File.delete("#{user_data["id"]}#{user_data["avatar"]}.png") if image_exitst(user_data["avatar"]) === true
      #File.delete("#{user_data["id"]}#{user_data["header"]}.png") if image_exitst(user_data["header"]) === true
    end

    @app = doorkeeper_token.application
    @token = Doorkeeper::AccessToken.where(token: access_token).last
    unless @token.present?
      @token = Doorkeeper::AccessToken.new(
        token: access_token,
        application: @app,
        resource_owner_id: @user.id,
        scopes: @app.scopes,
        expires_in: Doorkeeper.configuration.access_token_expires_in,
        use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
      )
      @token.save(validate: false)
    end

    result = {
      access_token: access_token,
      token_type: 'Bearer',
      scope: @app.scopes,
      created_at: @user.created_at,
      role: 'end-user',
      community_slug: "",
      is_active: true,
      is_account_setup_finished: @user.is_account_setup_finished,
      step: @user.step,
      user_id: @user.id
    }

    result = {
      data: result,
      status_code: 200
    }
    return result
  end

end