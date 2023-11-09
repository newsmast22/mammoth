module Mammoth
  class Dashboard::TimelinesStatusCheckService < BaseService

    def call
      check_endpoints!
    end

    private

    def check_endpoints!
      endpoints = Mammoth::Dashboard::EndPoint.all
      endpoints.each do |endpoint|
        response = fetch_api_data(endpoint.end_point_url, endpoint.http_method, endpoint.access_token)

        create_monitoring_status(endpoint, response)
      end
    end

    def fetch_api_data(url, http_method, access_token)
      protocol = Rails.env.development? ? 'http://' : 'https://'
      domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
      url = protocol + domain + url
      response = HTTParty.send(http_method.downcase, url, headers: { 'Authorization' => "Bearer #{access_token}" })
      response
    end
    
    def create_monitoring_status(endpoint, response)
      response_body = JSON.parse(response&.body)
      last_status_posted_datetime = response_body.present? ? response_body.first['created_at'] : nil
      
      if last_status_posted_datetime.present? && DateTime.parse(last_status_posted_datetime) >= 5.minutes.ago
        endpoint.monitoring_statuses.create(end_point_response: response.body, is_operational: true, monitoring_batch: DateTime.now.to_f)
      else
        endpoint.monitoring_statuses.create(is_operational: false, end_point_response: response.body, monitoring_batch: DateTime.now.to_f)
        Mammoth::Dashboard::TimelinesStatusMailer.alarm_email(Rails.env, endpoint.name, endpoint.max_active, last_status_posted_datetime, 'sithubo.stb97@gmail.com').deliver_now
      end
    end
  end
end
