module Mammoth::Api::V1
	class UserCommunitiesController < Api::BaseController
		before_action :require_authenticated_user!
    before_action -> { doorkeeper_authorize! :write, :read }
    def index
      @user = Mammoth::User.find(current_user.id)
      @communities = @user&.communities || []
      
      if @communities.any?
        render json: @communities
      else
        render json: { error: 'no communities found' }
      end
    end

    def create
      user_community_params[:interested_communities].each do |slug|
        @community = Mammoth::Community.find_by(slug: slug)
        @user_community = Mammoth::UserCommunity.create!(
            user_id: current_user.id,
            community_id: @community.id
        )
      end
      if user_community_params[:primary_community].present?
        @community = Mammoth::Community.find_by(slug: user_community_params[:primary_community])
        Mammoth::UserCommunity.find_by(community_id: @community.id, user_id: current_user.id)
                              .update(is_primary: true)
      end
	    render json: {message: 'User with community successfully saved!'}
		end

    private

    def user_community_params
		  params.require(:user_community).permit(:primary_community, interested_communities: [])
	  end
  end
end