module Mammoth::Api::V1
  class AccountsController < Api::BaseController
    before_action -> { authorize_if_got_token! :read, :'read:accounts' }, except: [:fedi_follow, :fedi_unfollow, :fedi_remove_from_followers, :fedi_block, :fedi_unblock, :fedi_mute, :fedi_unmute]
    before_action -> { doorkeeper_authorize! :follow, :write, :'write:follows' }, only: [:fedi_follow, :fedi_unfollow, :fedi_remove_from_followers]
    before_action -> { doorkeeper_authorize! :follow, :write, :'write:mutes' }, only: [:fedi_mute, :fedi_unmute]
    before_action -> { doorkeeper_authorize! :follow, :write, :'write:blocks' }, only: [:fedi_block, :fedi_unblock]

    before_action :require_user!
    before_action :set_account
    before_action :check_account_approval
    before_action :check_account_confirmation

    override_rate_limit_headers :follow, family: :follows

    # POST /api/v1/accounts/:id/fedi_follow
    def fedi_follow
      response = perform_action('follow')
      render json: response
    end

    # POST /api/v1/accounts/:id/fedi_unfollow
    def fedi_unfollow
      response = perform_action('unfollow')
      render json: response
    end

    # POST /api/v1/accounts/:id/fedi_remove_from_followers
    def fedi_remove_from_followers
      
    end

    # POST /api/v1/accounts/:id/fedi_block
    def fedi_block
      response = perform_action('block')
      render json: response
    end

    # POST /api/v1/accounts/:id/fedi_unblock
    def fedi_unblock
      response = perform_action('unblock')
      render json: response
    end

    # POST /api/v1/accounts/:id/fedi_mute
    def fedi_mute
      response = perform_action('mute')
      render json: response
    end

    # POST /api/v1/accounts/:id/fedi_unmute
    def fedi_unmute
      response = perform_action('unmute')
      render json: response
    end

    private

    def set_account
      @account = Account.find(params[:id])
    end

    def check_account_approval
      raise(ActiveRecord::RecordNotFound) if @account.local? && @account.user_pending?
    end

    def check_account_confirmation
      raise(ActiveRecord::RecordNotFound) if @account.local? && !@account.user_confirmed?
    end

    def account_params
      params.permit(:username, :email, :password, :agreement, :locale, :reason, :time_zone)
    end

    def perform_action(activity_type)
      Federation::ActionService.new.call(
        @account,
        current_account,
        activity_type: activity_type,
        doorkeeper_token: doorkeeper_token
      )
    end
  end
end
