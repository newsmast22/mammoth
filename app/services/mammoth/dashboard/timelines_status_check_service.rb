module Mammoth
  class Dashboard::TimelinesStatusCheckService < BaseService
    def call
      setup_protocol_and_domain
      login_account!
      check_endpoints!
    end

    private

    def setup_protocol_and_domain
      @protocol = Rails.env.development? ? 'http://' : 'https://'
      @domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
    end

    def login_account!
      client_id = ENV['LOGIN_CLIENT_ID']
      client_secret = ENV['LOGIN_CLIENT_SECRET']
      username = ENV['LOGIN_USER_NAME']
      password = ENV['LOGIN_PASSWORD']
      redirect_uri = ENV['LOGIN_REDIRECT_URI']
      scope = 'read write follow'

      response = authenticate(username, password, client_id, client_secret, redirect_uri, scope)
      access_token = response['access_token']
      Mammoth::Dashboard::EndPoint.update_all(access_token: access_token)
    end

    def authenticate(username, password, client_id, client_secret, redirect_uri, scope)
      response = HTTParty.post(
        "#{@protocol}#{@domain}/oauth/token",
        body: {
          grant_type: 'password',
          username: username,
          password: password,
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          scope: scope
        }
      )

      JSON.parse(response.body) if response.code == 200
    end

    def check_endpoints!
      Mammoth::Dashboard::EndPoint.all.each do |endpoint|
        response = fetch_api_data(endpoint.end_point_url, endpoint.http_method, endpoint.access_token)
        create_monitoring_status(endpoint, response)
      end
    end

    def fetch_api_data(url, http_method, access_token)
      url = "#{@protocol}#{@domain}#{url}"
      HTTParty.send(http_method.downcase, url, headers: { 'Authorization' => "Bearer #{access_token}" })
    end

    def create_monitoring_status(endpoint, response)
      response_body = JSON.parse(response&.body)
      last_status_posted_datetime = response_body&.first&.dig('created_at')

      if last_status_posted_datetime.present? && DateTime.parse(last_status_posted_datetime) >= 5.minutes.ago
        create_operational_status(endpoint, response)
      else
        create_non_operational_status(endpoint, response, last_status_posted_datetime)
      end
    end

    def create_operational_status(endpoint, response)
      endpoint.monitoring_statuses.create(
        end_point_response: response.body,
        is_operational: true,
        monitoring_batch: DateTime.now.to_f
      )
    end

    def create_non_operational_status(endpoint, response, last_status_posted_datetime)
      endpoint.monitoring_statuses.create(
        is_operational: false,
        end_point_response: response.body,
        monitoring_batch: DateTime.now.to_f
      )
      Mammoth::Dashboard::TimelinesStatusMailer.alarm_email(
        Rails.env,
        endpoint.name,
        endpoint.max_active,
        last_status_posted_datetime,
        ENV['LOGIN_USER_NAME']
      ).deliver_now
    end
  end
end
