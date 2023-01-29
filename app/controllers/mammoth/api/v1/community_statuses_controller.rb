module Mammoth::Api::V1
	class CommunityStatusesController < Api::BaseController
		before_action -> { authorize_if_got_token! :read, :'read:statuses' }
		before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
		before_action :require_user!, only:   [:create]
		before_action :set_status, only: [:show]
		include Authorization

		def index
			if params[:community_id].present?
				@community = Mammoth::Community.find_by(slug: params[:community_id])
				@statuses = @community&.statuses || []
			else
				@statuses = Mammoth::Status.all
			end
			if @statuses.any?
				render json: @statuses, each_serializer: Mammoth::StatusSerializer
			else
				render json: { error: "no statuses found " }
			end
		end

		def show
      @status = cache_collection([@status], Status).first
      render json: @status, serializer: Mammoth::StatusSerializer
    end

		def create
			time = Time.new

			@status = Mammoth::PostStatusService.new.call(
				current_user.account,
				text: community_status_params[:status],
				thread: @thread,
				media_ids: community_status_params[:media_ids],
				sensitive: community_status_params[:sensitive],
				spoiler_text: community_status_params[:spoiler_text],
				visibility: community_status_params[:visibility],
				language: community_status_params[:language],
				scheduled_at: community_status_params[:scheduled_at],
				application: doorkeeper_token.application,
				poll: community_status_params[:poll],
				idempotency: request.headers['Idempotency-Key'],
				with_rate_limit: true
			)

			content_type = "image/jpg"
			image = Paperclip.io_adapters.for(community_status_params[:image_data])
			image.original_filename = "status-#{time.usec.to_s}-#{}.jpg"

			@community = Mammoth::Community.find_by(slug: community_status_params[:community_id])

			@community_status = Mammoth::CommunityStatus.new()
			@community_status.status_id = @status.id
			@community_status.community_id = @community.id
			@community_status.save
			unless community_status_params[:image_data].nil?
				@community_status.image = image
				@community_status.save
			end
			render json: {message: 'status with community successfully saved!'}
		end

    private

		def set_status
			@status = Status.find(params[:id])
		end

		def community_status_params
			params.require(:community_status).permit(
				:community_id,
				:status,
				:image_data,
				:in_reply_to_id,
				:sensitive,
				:spoiler_text,
				:visibility,
				:language,
				:scheduled_at,
				media_ids: [],
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