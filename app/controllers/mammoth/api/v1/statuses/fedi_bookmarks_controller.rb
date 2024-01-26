# frozen_string_literal: true

class Mammoth::Api::V1::Statuses::FediBookmarksController < Api::V1::Statuses::BookmarksController

  before_action -> { doorkeeper_authorize! :write, :'write:bookmarks' }
  before_action :require_user!
  before_action :set_status, only: [:create, :destroy]

  def create
    response = perform_bookmark_unbookmark("bookmark")
    render json: response
  end

  def destroy
    response = perform_bookmark_unbookmark("unbookmark")
    render json: response
  end

  private

  def perform_bookmark_unbookmark(activity_type)
    Federation::StatusActionService.new.call(
      @status,
      current_account,
      activity_type: activity_type,
      doorkeeper_token: doorkeeper_token
    )
  end
end
