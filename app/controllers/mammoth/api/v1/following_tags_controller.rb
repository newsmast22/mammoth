module Mammoth::Api::V1

  class FollowingTagsController < Api::BaseController
    before_action -> { authorize_if_got_token! :read, :'read:accounts' }
    before_action :require_user!

    def index
      ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
        offset = params[:offset].present? ? params[:offset] : 0
        limit = params[:limit].present? ? params[:limit].to_i + 1 : 6
        default_limit = limit - 1

        @results = TagFollow.where(account: current_account).joins(:tag).eager_load(:tag).limit(limit).offset(offset)
        render json: @results.limit(params[:limit]).map(&:tag),root: 'data', each_serializer: REST::TagSerializer, relationships: TagRelationshipsPresenter.new(@results.map(&:tag), current_user&.account_id), current_user: current_user, adapter: :json, 
            meta: {
              pagination:
              { 
                total_objects: nil,
                has_more_objects: @results.size > default_limit ? true : false,
                offset: offset.to_i
              } 
            }
      end
    end

  end
end