# frozen_string_literal: true
module Mammoth::Api::V1

  class FollowerAccountsController < Api::BaseController
    before_action -> { authorize_if_got_token! :read, :'read:accounts' }
    before_action :set_account
    after_action :insert_pagination_headers
    before_action :require_user!

    def index

      offset = params[:offset].present? ? params[:offset] : 0
      limit = params[:limit].present? ? params[:limit].to_i + 1 : 6
      default_limit = limit - 1

      accounts = Mammoth::Account.follower_accouts(params[:account_id],current_account.id, offset, limit)

      render json: accounts.limit(params[:limit]),root: 'data', each_serializer: Mammoth::AccountSerializer, current_user: current_user, adapter: :json, 
					meta: {
						pagination:
						{ 
							total_objects: nil,
							has_more_objects: accounts.size > default_limit ? true : false,
              offset: offset.to_i
						} 
					}
    end

    private

    def set_account
      @account = Account.find(params[:account_id])
    end

    def load_accounts
      return [] if hide_results?

      scope = default_accounts
      scope = scope.where.not(id: current_account.excluded_from_timeline_account_ids) unless current_account.nil? || current_account.id == @account.id
      scope.merge(paginated_follows).to_a
    end

    def hide_results?
      @account.suspended? || (@account.hides_followers? && current_account&.id != @account.id) || (current_account && @account.blocking?(current_account))
    end

    def default_accounts
      Account.includes(:active_relationships, :account_stat).references(:active_relationships)
    end

    def paginated_follows
      Follow.where(target_account: @account).paginate_by_max_id(
        limit_param(DEFAULT_ACCOUNTS_LIMIT),
        params[:max_id],
        params[:since_id]
      )
    end

    def insert_pagination_headers
      set_pagination_headers(next_path, prev_path)
    end

    def next_path
      # if records_continue?
      #   api_v1_account_followers_url pagination_params(max_id: pagination_max_id)
      # end
    end

    def prev_path
      # unless @accounts.empty?
      #   api_v1_account_followers_url pagination_params(since_id: pagination_since_id)
      # end
    end

    def pagination_max_id
      @accounts.last.active_relationships.first.id
    end

    def pagination_since_id
      @accounts.first.active_relationships.first.id
    end

    def records_continue?
      @accounts.size == limit_param(DEFAULT_ACCOUNTS_LIMIT)
    end

    def pagination_params(core_params)
      params.slice(:limit).permit(:limit).merge(core_params)
    end
  end
  
end  