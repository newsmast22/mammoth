module Mammoth::Api::V1
	class CommunityStatusesController < Api::BaseController
		skip_before_action :require_authenticated_user!
		#before_action :set_community, only: %i[show update destroy]

		def index
				if params[:community_id].present?
						@community = Mammoth::Community.find_by(slug: params[:community_id])
						@statuses = @community&.statuses || []
				else
						@statuses = Mammoth::Status.all
				end
				if @statuses.any?
						render json: @statuses, each_serializer: REST::StatusSerializer
				else
						render json: { error: "no statuses found " }
				end
		end

		def create
			@status = PostStatusService.new.call(
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

			@community = Mammoth::Community.find_by(slug: community_status_params[:community_id])
			@community_status = Mammoth::CommunityStatus.create!(
					status_id: @status.id,
					community_id: @community.id
			)
			render json: {message: 'status with community successfully saved!'}
		end

    private

			def community_status_params
				params.require(:community_status).permit(:status, :media_ids, :sensitive, 
									:spoiler_text, :visibility, :language,
									:scheduled_at, :poll, :community_id)
			end
  end
end