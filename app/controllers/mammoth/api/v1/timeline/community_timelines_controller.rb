module Mammoth::Api::V1::Timeline
  class CommunityTimelinesController < Api::BaseController
    before_action :require_user!
    before_action :set_max_id, only: [:all, :recommended] 
    before_action :create_service, only: [:all, :recommended] 
    before_action -> { doorkeeper_authorize! :read , :write}

    def all
      @statuses = @timeline_service.call
      format_json
    end

    def recommended
      @statuses = @timeline_service.call
      format_json
    end

    private 

    def set_max_id
      @max_id = params[:max_id]
      @community_slug = params[:id]
      @current_community = Mammoth::Community.find_by(slug: @community_slug)
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
      @timeline_service = Mammoth::CommunityTimelineService.new(current_account, @max_id, current_user, @current_community)
    end
  end 
end