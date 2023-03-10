module Mammoth::Api::V1
	class UserCommunitiesController < Api::BaseController
		before_action :require_authenticated_user!
    before_action -> { doorkeeper_authorize! :write, :read }

    def index
      @user = Mammoth::User.find(current_user.id)
      @communities = @user&.communities || []
      @user_communities = Mammoth::UserCommunity.find_by(user_id: current_user.id,is_primary: true)
      
      unless @communities.empty?
        data = []
        @communities.each do |community|
          data << {
            id: community.id.to_s,
            is_primary: community.id == @user_communities.community_id ? true : false,
            name: community.name,
            slug: community.slug,
            image_file_name: community.image_file_name,
            image_content_type: community.image_content_type,
            image_file_size: community.image_file_size,
            image_updated_at: community.image_updated_at,
            description: community.description,
            image_url: community.image.url,
            collection_id: community.collection.id,
            followers: Mammoth::UserCommunity.where(community_id: community.id).size,
            created_at: community.created_at,
            updated_at: community.updated_at
          }
        end
        data = data.sort_by {|h| [h[:is_primary] ? 0 : 1,h[:slug]]}
        render json: data
      else
        render json: { error: 'no communities found' }
      end
    end

    def create
      Mammoth::UserCommunity.where(user_id: current_user.id).destroy_all
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

      #Begin::Create UserTimeLineSetting
      Mammoth::UserTimelineSetting.where(user_id: current_user.id).destroy_all
      Mammoth::UserTimelineSetting.create!(
        user_id: current_user.id,
        selected_filters: {
          default_country: current_user.account.country,
          location_filter: {
            selected_countries: [],
            is_location_filter_turn_on: false
          },
          is_filter_turn_on: true
        }
      )
      #End:Create UserTimeLineSetting
	    render json: {message: 'User with community successfully saved!'}
		end

    def join_unjoin_community
      @community = Mammoth::Community.find_by(slug: params[:community_id])
      @joined_user_community = Mammoth::UserCommunity.where(community_id: @community.id, user_id: current_user.id).last
      unless @joined_user_community.present?
        Mammoth::UserCommunity.create!(
          user_id: current_user.id,
          community_id: @community.id
        )
        render json: {message: 'User with community successfully joined!'}
      else
        @joined_user_community.destroy
        render json: {message: 'User with community successfully unjoied!'}
      end
    end

    private

    def user_community_params
		  params.require(:user_community).permit(:primary_community, interested_communities: [])
	  end
  end
end