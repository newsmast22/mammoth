module Mammoth::Api::V1
	class UserCommunitiesController < Api::BaseController
		before_action :require_authenticated_user!
    before_action -> { doorkeeper_authorize! :write, :read }
    def index
      @user = Mammoth::User.find(current_user.id)
      @communities = @user&.communities || []
      @user_communities = Mammoth::UserCommunity.find_by(user_id: current_user.id,is_primary: true)

      
      if @communities.any?
        data = []

        @communities.each do |community|
          if community.id == @user_communities.community_id
            @flag  = true
          else
            @flag = false
          end
          data << {
            id: community.id.to_s,
            is_primary: @flag,
            name: community.name,
            slug: community.slug,
            image_file_name: community.image_file_name,
            image_content_type: community.image_content_type,
            image_file_size: community.image_file_size,
            image_updated_at: community.image_updated_at,
            description: community.description,
            collection_id: 3,
            created_at: community.created_at,
            updated_at: community.updated_at
          }
        end
        render json: data
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