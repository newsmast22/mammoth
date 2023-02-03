module Mammoth::Api::V1
	class CommunityStatusesController < Api::BaseController
		before_action -> { authorize_if_got_token! :read, :'read:statuses' }
		before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
		before_action :require_user!, except: [:show, :context]
    before_action :set_status, only: [:show, :context]
		before_action :set_thread, only: [:create]

		include Authorization

		# This API was originally unlimited, pagination cannot be introduced without
		# breaking backwards-compatibility. Arbitrarily high number to cover most
		# conversations as quasi-unlimited, it would be too much work to render more
		# than this anyway
		CONTEXT_LIMIT = 4_096

		# This remains expensive and we don't want to show everything to logged-out users
		ANCESTORS_LIMIT         = 40
		DESCENDANTS_LIMIT       = 60
		DESCENDANTS_DEPTH_LIMIT = 20

		def context
			ancestors_limit         = CONTEXT_LIMIT
			descendants_limit       = CONTEXT_LIMIT
			descendants_depth_limit = nil
	
			if current_account.nil?
				ancestors_limit         = ANCESTORS_LIMIT
				descendants_limit       = DESCENDANTS_LIMIT
				descendants_depth_limit = DESCENDANTS_DEPTH_LIMIT
			end
	
			ancestors_results   = @status.in_reply_to_id.nil? ? [] : @status.ancestors(ancestors_limit, current_account)
			descendants_results = @status.descendants(descendants_limit, current_account, descendants_depth_limit)
			loaded_ancestors    = cache_collection(ancestors_results, Status)
			loaded_descendants  = cache_collection(descendants_results, Status)
	
			@context = Context.new(ancestors: loaded_ancestors, descendants: loaded_descendants)
			statuses = [@status] + @context.ancestors + @context.descendants
	
			render json: @context, serializer: Mammoth::ContextSerializer, relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id)
		end

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

			if community_status_params[:community_id].nil?
				@user_community = Mammoth::UserCommunity.find_by(user_id: current_user.id, is_primary: true).community
				@community_id = @user_community.id
			else
				@community_id = Mammoth::Community.find_by(slug: community_status_params[:community_id]).id
			end

			unless @thread.nil?
				@community_id = Mammoth::CommunityStatus.find_by(status_id: @thread.id).community_id
			end
 
			@community_status = Mammoth::CommunityStatus.new()
			@community_status.status_id = @status.id
			@community_status.community_id = @community_id
			@community_status.save
			unless community_status_params[:image_data].nil?
				@community_status.image = image
				@community_status.save
			end
			render json: {message: 'status with community successfully saved!'}
		end

		def get_community_statues
			@user_communities = Mammoth::User.find(current_user.id).user_communities
			user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)

			community = Mammoth::Community.find_by(slug: params[:id])
			community_statuses = Mammoth::CommunityStatus.where(community_id: community.id)
			community_followed_user_counts = Mammoth::UserCommunity.where(community_id: community.id).size
			unless community_statuses.empty?
				community_statues_ids= community_statuses.pluck(:status_id).map(&:to_i)
				@statuses = Status.where(id: community_statues_ids)
				render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, adapter: :json, 
				meta: { 
					community_followed_user_counts: community_followed_user_counts,
					community_name: community.name,
					community_description: community.description,
					community_url: community.image.url,
					community_slug: community.slug,
					is_joined: user_communities_ids.include?(community.id), 
					}
			else
				render json: {error: "Record not found"}
			end
		end

    private

		def set_status
			@status = Status.find(params[:id])
		end

		def set_thread
			@thread = Status.find(community_status_params[:in_reply_to_id]) if community_status_params[:in_reply_to_id].present?
			authorize(@thread, :show?) if @thread.present?
		  rescue ActiveRecord::RecordNotFound, Mastodon::NotPermittedError
			render json: { error: I18n.t('statuses.errors.in_reply_not_found') }, status: 404
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