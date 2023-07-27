module Mammoth::Api::V1::Timeline
  class TimelinesController < Api::BaseController
    before_action :require_user!
    before_action :create_policy, except: [:index, :all, :primary]
    before_action -> { doorkeeper_authorize! :read , :write}

    def primary
      max_id = params[:max_id]
      @statuses = Mammoth::TimelineService.primary_timeline(current_account, max_id, current_user)
      Mammoth::TimelineService.format_json(@statuses)
    end

    private 

    def create_policy
      @status_policy = Mammoth::StatusPolicy.new(current_account, status)
    end
  end
end