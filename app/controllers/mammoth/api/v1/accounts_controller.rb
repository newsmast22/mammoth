module Mammoth::Api::V1
  class AccountsController < Api::BaseController
    before_action -> { authorize_if_got_token! :read, :'read:accounts' }, except: [:fedi_follow, :fedi_unfollow, :fedi_remove_from_followers, :fedi_block, :fedi_unblock, :fedi_mute, :fedi_unmute]
    before_action -> { doorkeeper_authorize! :follow, :write, :'write:follows' }, only: [:fedi_follow, :fedi_unfollow, :fedi_remove_from_followers]
    before_action -> { doorkeeper_authorize! :follow, :write, :'write:mutes' }, only: [:fedi_mute, :fedi_unmute]
    before_action -> { doorkeeper_authorize! :follow, :write, :'write:blocks' }, only: [:fedi_block, :fedi_unblock]

    before_action :require_user!
    before_action :set_account, except: [:fedi_tag_commu_count, :fedi_profile_update]
    before_action :check_account_approval, except: [:fedi_tag_commu_count, :fedi_profile_update]
    before_action :check_account_confirmation, except: [:fedi_tag_commu_count, :fedi_profile_update]

    override_rate_limit_headers :follow, family: :follows

    def fedi_profile_update
      options = {
        activity_type: 'update_credentials',
        doorkeeper_token: doorkeeper_token,
        display_name: account_update_params[:display_name],
        note: account_update_params[:note],
        avatar: account_update_params[:avatar],
        header: account_update_params[:header],
        locked: account_update_params[:locked],
        bot: account_update_params[:bot],
        discoverable: account_update_params[:discoverable],
        hide_collections: account_update_params[:hide_collections],
        indexable: account_update_params[:indexable],
        fields_attributes: account_update_params[:fields_attributes]
      }

      Federation::AccountActionService.new.call(
        current_account,
        current_account,
        options
      )
    end

    def fedi_tag_commu_count
      response = Federation::TagCommuCountService.new.call(current_account)
      render json: response
    end

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
      Federation::AccountActionService.new.call(
        @account,
        current_account,
        activity_type: activity_type,
        doorkeeper_token: doorkeeper_token
      )
    end
    
    def account_update_params
      params.permit(
        :display_name,
        :note,
        :avatar,
        :header,
        :locked,
        :bot,
        :discoverable,
        :hide_collections,
        :indexable,
        fields_attributes: [:name, :value]
      )
    end
  end
end
