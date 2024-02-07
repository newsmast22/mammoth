# frozen_string_literal: true

class Mammoth::Api::V1::Statuses::FediPinsController < Api::V1::Statuses::PinsController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }
  before_action :require_user!
  before_action :set_status

  def create
    response = perform_pin_unpin("pin")
    render json: response
  end

  def destroy
    response = perform_pin_unpin("unpin")
    render json: response
  end

  private

  def perform_pin_unpin(activity_type)
    Federation::StatusActionService.new.call(
      @status,
      current_account,
      activity_type: activity_type,
      doorkeeper_token: doorkeeper_token
    )
  end
end
