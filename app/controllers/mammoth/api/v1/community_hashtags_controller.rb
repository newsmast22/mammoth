# frozen_string_literal: true

module Mammoth::Api::V1
  class CommunityHashtagsController < Api::BaseController
    before_action :require_user!
    before_action -> { doorkeeper_authorize! :read, :write }

    def index
      ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
        community = Mammoth::Community.find_by(slug: params[:slug])

        if community.nil?
          return render json: { error: 'Community not found' }, status: :not_found
        end

        community_hashtags = Mammoth::CommunityHashtag
                              .where(community_id: community.id)
                              .where(is_incoming: truthy?(params[:is_incoming]))

        render json: { data: community_hashtags }, status: :ok
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end

    private

    def truthy?(value)
      ActiveRecord::Type::Boolean.new.cast(value)
    end
  end
end
