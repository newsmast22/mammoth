module Mammoth::Api::V1
  class TagTimelinesController < Api::BaseController
    before_action :load_tag
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def show
      if params[:id].present?
        @statuses = @tag.statuses.where(reply: false).order(created_at: :desc).take(10)
        render json: @statuses,root: 'data', 
        each_serializer: Mammoth::StatusSerializer, adapter: :json
      else
        render json: {
          error: "Record not found"
         }
      end      

    end

    private

    def load_tag
      @tag = Tag.find_normalized(params[:id])
    end
  end
end