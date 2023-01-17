module Mammoth::Api::V1
	class StatuesWithCommunitiesController < Api::BaseController
		skip_before_action :require_authenticated_user!
		#before_action :set_community, only: %i[show update destroy]

        def create_statues_with_communities

            @status = PostStatusService.new.call(
                current_user.account,
                text: status_with_community_params[:status],
                thread: @thread,
                media_ids: status_with_community_params[:media_ids],
                sensitive: status_with_community_params[:sensitive],
                spoiler_text: status_with_community_params[:spoiler_text],
                visibility: status_with_community_params[:visibility],
                language: status_with_community_params[:language],
                scheduled_at: status_with_community_params[:scheduled_at],
                application: doorkeeper_token.application,
                poll: status_with_community_params[:poll],
                idempotency: request.headers['Idempotency-Key'],
                with_rate_limit: true
            )

            @community = Mammoth::Community.find_by(slug: params[:community_id])
            @community_status = Mammoth::CommunityStatus.create!(
                status_id: @status.id,
                community_id: @community.id
            )
			render json: {message: 'status with community succfully!'}
		end

        private
        def status_with_community_params
			params.require(:status_with_community).permit(:status, :media_ids,:sensitive,:spoiler_text,:visibility,:language,:scheduled_at,:poll,:community_id)
		end
    end
end