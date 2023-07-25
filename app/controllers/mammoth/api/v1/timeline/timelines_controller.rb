module Mammoth::Api::V1::Timeline
  class TimelinesController < Api::BaseController
    before_action :require_user!
    before_action :create_policy, except: [:index,:all]
    before_action -> { doorkeeper_authorize! :read , :write}

    def all
      max_id = params[:max_id]
      @statuses = Mammoth::StatusPolicy.policy_scope(current_account,current_user,max_id)
      unless @statuses.empty?
          before_limit_statuses = @statuses
          @statuses = @statuses.order(created_at: :desc).limit(5)
          render json: @statuses, root: 'data', 
                                  each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
                                  meta: {
                                    pagination:
                                    { 
                                      total_objects: before_limit_statuses.size,
                                      has_more_objects: 5 <= before_limit_statuses.size ? true : false
                                    } 
                                  }
      else
        render json: {
          data: [],
          meta: {
            pagination:
            { 
              total_objects: 0,
              has_more_objects: false
            } 
          }
        }
      end
    end

    private 
    def create_policy
      @status_policy = Mammoth::StatusPolicy.new(current_account, status)
    end
  end
end