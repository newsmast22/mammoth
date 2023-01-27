# frozen_string_literal: true
module Mammoth::Api::V1
  class MammothTimelines::PublicController < Api::BaseController
    before_action :require_user!, only: [:show]
    after_action :insert_pagination_headers, unless: -> { @statuses.empty? }

    def show
      statuses = load_statuses
      user_communities= Mammoth::UserCommunity.select("community_id").where(user_id: current_user.id).group("community_id")
      user_communities_ids = Mammoth::UserCommunity.where(user_id: current_user.id).pluck(:community_id).map(&:to_i)
      statues_ids = Mammoth::CommunityStatus.where(community_id: user_communities_ids).pluck(:status_id).map(&:to_i)
      statues_data = Status.where(id: statues_ids)

      #109743770263858171
      # data = statuses.to_a.where(id: 109743770263858171)

      @statuses = statues_data
      render json: @statuses, each_serializer: REST::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id)
    # render json: {data: data}
    end

    private

    def require_auth?
      !Setting.timeline_preview
    end

    def load_statuses
      cached_public_statuses_page
    end

    def cached_public_statuses_page
      cache_collection(public_statuses, Status)
    end

    def public_statuses
      public_feed.get(
        limit_param(DEFAULT_STATUSES_LIMIT),
        params[:max_id],
        params[:since_id],
        params[:min_id]
      )
    end

    def public_feed
      PublicFeed.new(
        current_account,
        local: truthy_param?(:local),
        remote: truthy_param?(:remote),
        only_media: truthy_param?(:only_media)
      )
    end

    def insert_pagination_headers
      set_pagination_headers(next_path, prev_path)
    end

    def pagination_params(core_params)
      params.slice(:local, :remote, :limit, :only_media).permit(:local, :remote, :limit, :only_media).merge(core_params)
    end

    def next_path
      api_v1_mammoth_timelines_public_url pagination_params(max_id: pagination_max_id)
    end

    def prev_path
      api_v1_mammoth_timelines_public_url pagination_params(min_id: pagination_since_id)
    end

    def pagination_max_id
      @statuses.last.id
    end

    def pagination_since_id
      @statuses.first.id
    end
  end
end
