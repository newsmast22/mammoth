# frozen_string_literal: true
module Mammoth::Api::V1

  class ReblogStatusesController < Api::BaseController
    include Authorization

    before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
    before_action :require_user!
    before_action :set_reblog, only: [:create]

    override_rate_limit_headers :create, family: :statuses

    def create
      @status = Mammoth::ReblogService.new.call(current_account, @reblog, reblog_params)

      @community_id = Mammoth::CommunityStatus.find_by(status_id: params[:status_id]).community_id

      @community_status = Mammoth::CommunityStatus.new()
			@community_status.status_id = @status.id
			@community_status.community_id = @community_id
			@community_status.save
			unless params[:image_data].nil?
				image = Paperclip.io_adapters.for(params[:image_data])
				@community_status.image = image
				@community_status.save
			end

      render json: @status, serializer: Mammoth::StatusSerializer
    end

    def destroy
      @status = current_account.statuses.find_by(reblog_of_id: params[:status_id])

      if @status
        authorize @status, :unreblog?
        @status.discard
        RemovalWorker.perform_async(@status.id)
        @reblog = @status.reblog
      else
        @reblog = Status.find(params[:status_id])
        authorize @reblog, :show?
      end

      render json: @reblog, serializer: Mammoth::StatusSerializer, relationships: StatusRelationshipsPresenter.new([@status], current_account.id, reblogs_map: { @reblog.id => false })
    rescue Mastodon::NotPermittedError
      not_found
    end

    private

    def set_reblog
      @reblog = Status.find(params[:status_id])
      authorize @reblog, :show?
    rescue Mastodon::NotPermittedError
      not_found
    end

    def reblog_params
      params.permit(
        :visibility,
        :status
      )
    end
  end

end