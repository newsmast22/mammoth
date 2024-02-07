# frozen_string_literal: true

class Mammoth::Api::V1::Statuses::FediReblogsController < Api::V1::Statuses::ReblogsController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }
  before_action :require_user!
  before_action :set_status

  def create
    response = perform_reblog_unreblog("reblog")
    render json: response
  end

  def destroy
    response = perform_reblog_unreblog("unreblog")
    render json: response
  end

  private

  def perform_reblog_unreblog(activity_type)
    Federation::StatusActionService.new.call(
      @status,
      current_account,
      activity_type: activity_type,
      doorkeeper_token: doorkeeper_token
    )
  end

  def set_status
    @status = Status.find(params[:status_id])
  end
end
