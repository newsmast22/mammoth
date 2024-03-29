module Mammoth::Api::V1
  class FollowingTimelinesController < Api::BaseController
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
    before_action :set_max_id, only: [:index] 
    before_action :create_service, only: [:index] 

    def index
      @statuses = @timeline_service.call
      format_json
    end

    private 

    def set_max_id
      @max_id = params[:max_id]
      @page_no = params[:page_no]
    end

    def format_json
      unless @statuses.empty?
        render json: @statuses, root: 'data', 
                                each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
                                meta: {
                                  pagination:
                                  { 
                                    total_objects: nil,
                                    has_more_objects: 5 <= @statuses.size ? true : false
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

    def create_service
      @timeline_service = Mammoth::TimelineService.new(current_account, @max_id, current_user,@page_no)
    end

    def create_policy
      @status_policy = Mammoth::StatusPolicy.new(current_account, status)
    end
  end
end