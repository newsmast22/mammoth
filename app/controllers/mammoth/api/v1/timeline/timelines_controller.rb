module Mammoth::Api::V1::Timeline
  class TimelinesController < Api::BaseController
    before_action :require_user!
    before_action :create_policy, except: [:index,:all]
    before_action -> { doorkeeper_authorize! :read , :write}

    def all
      max_id = params[:max_id]
      @statuses = Mammoth::StatusPolicy.policy_scope(current_account,max_id)
      byebug
    end

    private 
    def create_policy
      @status_policy = Mammoth::StatusPolicy.new(current_account, status)
    end
  end
end