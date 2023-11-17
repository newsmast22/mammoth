module Mammoth
  class Dashboard::TimelinesStatusMailer < ApplicationMailer
    def alarm_email(environment, endpoint_name, max_active_seconds, last_status_posted_datetime)
      @environment = environment
      @endpoint_name = endpoint_name
      @max_active_seconds = max_active_seconds
      @last_status_posted_datetime = last_status_posted_datetime

      emails = ENV['TIMELINES_NOTICE_RECIPIENTS'].split(',')
      to_email = emails.first
      cc_emails = emails[1..-1]
      mail(to: to_email, cc: cc_emails, subject: "[#{environment}] END POINT #{endpoint_name} is not in operational")
    end
  end
end
