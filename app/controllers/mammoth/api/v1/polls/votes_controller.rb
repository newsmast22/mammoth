# frozen_string_literal: true

class Mammoth::Api::V1::Polls::VotesController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
  before_action :require_user!
  before_action :set_poll

  def fedi_vote
    response = Federation::VoteService.new.call(
                              @poll,
                              current_account,
                              activity_type: 'create',
                              doorkeeper_token: doorkeeper_token,
                              choices: params[:choices]
                            )

    render json: response
  end

  private

  def set_poll
    @poll = Poll.attached.find(params[:id])
  end

  def vote_params
    params.permit(choices: [])
  end
end
