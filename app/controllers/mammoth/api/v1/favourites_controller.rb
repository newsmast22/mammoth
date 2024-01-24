module Mammoth::Api::V1
  class FavouritesController < Api::BaseController
    include Authorization

    before_action -> { doorkeeper_authorize! :read, :'read:favourites' }
    before_action :require_user!
    before_action :set_status

    def favourite
      response = perform_favourite_unfavourite(action_name)
      render json: response
    end

    def unfavourite
      response = perform_favourite_unfavourite(action_name)
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
        current_account,
        @status,
        activity_type: activity_type,
        doorkeeper_token: doorkeeper_token
      )
    end
  end
end
