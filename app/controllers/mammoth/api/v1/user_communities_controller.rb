module Mammoth::Api::V1
	class UserCommunitiesController < Api::BaseController
		before_action :require_authenticated_user!
    before_action :prepare_service, only: [ :index ]
    before_action -> { doorkeeper_authorize! :write, :read }

    def index
      data = @service.get_user_communities
      if data.count > 0
        render json: data
      else
        render json: { error: 'no communities found' }
      end
    end

    def create
      @user  = Mammoth::User.find(current_user.id)
      Mammoth::UserCommunity.where(user_id: current_user.id).destroy_all
      user_community_params[:interested_communities].each do |slug|
        @community = Mammoth::Community.find_by(slug: slug)
        @user_community = Mammoth::UserCommunity.create!(
            user_id: current_user.id,
            community_id: @community.id
        )
        # Newsmast::CommunityMergeWorker.perform_async([@community&.id], current_user&.account&.id)
      end
      @user.step = "communities"
      @user.save(validate: false)
      if user_community_params[:primary_community].present?
        @community = Mammoth::Community.find_by(slug: user_community_params[:primary_community])
        Mammoth::UserCommunity.find_by(community_id: @community.id, user_id: current_user.id)
                              .update(is_primary: true)
        @user.step = nil
        @user.is_account_setup_finished = true
        @user.save(validate: false)                      
      end

      #Begin::Create UserTimeLineSetting
      userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id)
      if userTimeLineSetting.blank?
        userTimeLineSetting.destroy_all
        Mammoth::UserTimelineSetting.create!(
          user_id: current_user.id,
          selected_filters: {
            default_country: current_user.account.country,
            location_filter: {
              selected_countries: [],
              is_location_filter_turn_on: false
            },
            is_filter_turn_on: false,
            source_filter: {
              selected_media: [],
              selected_voices: [],
              selected_contributor_role: []
            },
            communities_filter: {
              selected_communities: []
            }
          }
        )
      end
      #End:Create UserTimeLineSetting

      #Begin::Create UserCommunitySetting
      userCommunitySetting = Mammoth::UserCommunitySetting.where(user_id: current_user.id)
      if userCommunitySetting.blank?
        userCommunitySetting.destroy_all
        Mammoth::UserCommunitySetting.create!(
          user_id: current_user.id,
          selected_filters: {
            default_country: current_user.account.country,
            location_filter: {
              selected_countries: [],
              is_location_filter_turn_on: false
            },
            is_filter_turn_on: false,
            source_filter: {
              selected_media: [],
              selected_voices: [],
              selected_contributor_role: []
            },
            communities_filter: {
              selected_communities: []
            }
          }
        )
      end
      #End:Create UserCommunitySetting
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
        # Newsmast::CommunityMergeWorker.perform_async([@community&.id], current_user&.account&.id)
        render json: {message: 'User with community successfully joined!'}
      else
        # Newsmast::CommunityUnmergeWorker.perform_async([@community&.id], current_user&.account&.id)
        return render json: {message: 'User with community unsuccessfully unjoied!'} if @joined_user_community.is_primary === true
        @joined_user_community.destroy
        render json: {message: 'User with community successfully unjoied!'}
      end
    end

    def join_all_community
      collection = Mammoth::Collection.find_by(slug: params[:collection_id])
      communities = collection.communities
      unless communities.blank?
        communities.each do |community|
          Mammoth::UserCommunity.where(community_id: community.id, user_id: current_user.id).first_or_create
        end
        # Newsmast::CommunityMergeWorker.perform_async(communities&.pluck(:id), current_user&.account&.id)
        render json: {message: 'User with community successfully joined!'}
      else
        render json: { error: 'no communities found' }
      end 
    end

    def unjoin_all_community
      collection = Mammoth::Collection.find_by(slug: params[:collection_id])
      communities = collection.communities
      unless communities.blank?
        Mammoth::UserCommunity.where(user_id: current_user.id, community_id: collection.communities.pluck(:id).map(&:to_i)).destroy_all
        # Newsmast::CommunityUnmergeWorker.perform_async(communities&.pluck(:id), current_user&.account&.id)
        render json: {message: 'User with community successfully joined!'}
      else
        render json: { error: 'no communities found' }
      end 
    end

    def change_primary_community
      if params[:slug].present?

        community = Mammoth::Community.where(slug: params[:slug]).last
        joined_user_community = Mammoth::UserCommunity.where(community_id: community.id, user_id: current_user.id).last

        if joined_user_community.present?
          user_primary_community = Mammoth::UserCommunity.where(is_primary: true, user_id: current_user.id)
          if user_primary_community.present?
            user_primary_community.update(is_primary: false)
          end
          joined_user_community.update(is_primary: true)
        else
          Mammoth::UserCommunity.create!(
            user_id: current_user.id,
            community_id: community.id,
            is_primary: true
          )
        end                 
        render json: {message: 'User with community successfully saved!'}
      else
        render json: { error: 'no communities found' }
      end

    end

    private

    def prepare_service
      @service = Mammoth::UserCommunitiesService.new(params, current_user)
    end

    def user_community_params
		  params.require(:user_community).permit(:primary_community, interested_communities: [])
	  end
  end
end