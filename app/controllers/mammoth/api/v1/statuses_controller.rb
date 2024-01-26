module Mammoth::Api::V1
  class StatusesController < Api::BaseController
    include Authorization
    before_action -> { authorize_if_got_token! :read, :'read:statuses' }
  	before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
		before_action :require_user!
    before_action :set_thread, only: [:create, :fedi_create]

    def fedi_create
      create
    end

    def fedi_destroy 
      delete
    end

    def create
      options = {
        activity_type: status_params[:in_reply_to_id].present? ? 'reply' : 'create',
        doorkeeper_token: doorkeeper_token,
        language: status_params[:language],
        media_ids: status_params[:image_data],
        poll: status_params[:poll],
        sensitive: status_params[:sensitive],
        spoiler_text: '',
        status: status_params[:status],
        visibility: status_params[:visibility]
      }
      @status = Federation::ActionService.new.call(
        @thread,
        current_account,
        options
      )
      render json: @status
    end

    def delete
      @status = Status.where(account: current_account).find(params[:id])
      authorize @status, :destroy?
      @response = Federation::ActionService.new.call(
        @status,
        current_account,
        activity_type: 'delete',
        doorkeeper_token: doorkeeper_token
      )
        
      render json: @response
    end

    private
    def set_thread
      @thread = Status.find(status_params[:in_reply_to_id]) if status_params[:in_reply_to_id].present?
      authorize(@thread, :show?) if @thread.present?
    rescue ActiveRecord::RecordNotFound, Mastodon::NotPermittedError
      render json: { error: I18n.t('statuses.errors.in_reply_not_found') }, status: 404
    end

    def status_params
      params.permit(
        :status,
        :in_reply_to_id,
        :sensitive,
        :spoiler_text,
        :visibility,
        :language,
        :scheduled_at,
        :is_only_for_followers,
        :is_meta_preview,
        :text_count,
        allowed_mentions: [],
        media_ids: [],
        media_attributes: [
          :id,
          :thumbnail,
          :description,
          :sensitive,
          :focus,
        ],
        community_ids: [],
        poll: [
          :multiple,
          :hide_totals,
          :expires_in,
          options: [],
        ]
      )
    end
  end
end
