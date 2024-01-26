module Mammoth::Api::V1::Statuses
  class FediFavouritesController < Api::BaseController
    include Authorization

    before_action -> { doorkeeper_authorize! :read, :'read:favourites' }
    before_action :require_user!
    before_action :set_status

    def create
      response = perform_favourite_unfavourite('favourite')
      render json: response
    end

    def destroy
      response = perform_favourite_unfavourite('unfavourite')
      render json: response
    end

    private
    def set_status
      @status = Status.find(params[:status_id])
      authorize @status, :show?
    rescue Mastodon::NotPermittedError
      not_found
    end

    def perform_favourite_unfavourite(activity_type)
      Federation::ActionService.new.call(
        @status,
        current_account,
        activity_type: activity_type,
        doorkeeper_token: doorkeeper_token
      )
    end
  end
end
