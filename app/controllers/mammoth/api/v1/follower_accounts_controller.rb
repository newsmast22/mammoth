# frozen_string_literal: true
module Mammoth::Api::V1

  class FollowerAccountsController < Api::BaseController
    before_action -> { authorize_if_got_token! :read, :'read:accounts' }
    before_action :set_account
    after_action :insert_pagination_headers

    def index
      # @accounts = load_accounts
      # render json: @accounts, current_user: current_user, each_serializer: Mammoth::AccountSerializer

      #begin::custom following accounts for user
      following_account = Follow.where(target_account_id: @account.id)
      pagination_max_query = "AND accounts.id < :max_id" if params[:max_id].present?
      accounts = Account.where("
        accounts.id IN (:following_account_ids) AND accounts.id != #{current_account.id} #{pagination_max_query}",
        following_account_ids: following_account.pluck(:account_id) , max_id: params[:max_id]
      ).order(id: :desc)
      
      before_limit_account = accounts
      accounts = accounts.limit(10)
      return render json: accounts,root: 'data', each_serializer: Mammoth::AccountSerializer, current_user: current_user, adapter: :json, 
					meta: {
						pagination:
						{ 
							total_objects: before_limit_account.size,
							has_more_objects: 10 <= before_limit_account.size ? true : false
						} 
					}
      #end::custom following accounts for user

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