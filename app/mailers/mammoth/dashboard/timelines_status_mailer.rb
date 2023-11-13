module Mammoth
  class Dashboard::TimelinesStatusMailer < ApplicationMailer
    def alarm_email(environment, endpoint_name, max_active_seconds, last_status_posted_datetime, to_email)
      @environment = environment
      @endpoint_name = endpoint_name
      @max_active_seconds = max_active_seconds
      @last_status_posted_datetime = last_status_posted_datetime
      mail(to: to_email, subject: "[#{environment}] END POINT #{endpoint_name} is not in operational")
    end
  end
end
