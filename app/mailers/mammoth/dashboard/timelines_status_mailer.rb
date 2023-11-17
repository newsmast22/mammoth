module Mammoth
  class Dashboard::TimelinesStatusMailer < ApplicationMailer
    def alarm_email(environment, endpoint_name, max_active_seconds, last_status_posted_datetime)
      @environment = environment
      @endpoint_name = endpoint_name
      @max_active_seconds = max_active_seconds
      @last_status_posted_datetime = last_status_posted_datetime

      to_emails = ENV['TIMELINES_NOTICE_RECIPIENTS'].split(',')
      to_emails.each do |to_email|
        mail(to: to_email, subject: "[#{environment}] END POINT #{endpoint_name} is not in operational")
      end
    end
  end
end
