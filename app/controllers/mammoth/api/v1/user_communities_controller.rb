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
            user_id: @user.id.to_s,
            is_primary: community.id == (@user_communities&.community_id || 0) ? true : false,
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

        if params[:community_slug].present?
          new_community = Mammoth::Community.find_by(slug: params[:community_slug])
          unless data.any? { |obj| obj[:slug] == params[:community_slug] }
            data << {
              id: new_community.id.to_s,
              user_id: @user.id.to_s,
              is_primary:  false,
              name: new_community.name,
              slug: new_community.slug,
              image_file_name: new_community.image_file_name,
              image_content_type: new_community.image_content_type,
              image_file_size: new_community.image_file_size,
              image_updated_at: new_community.image_updated_at,
              description: new_community.description,
              image_url: new_community.image.url,
              collection_id: new_community.collection.id,
              followers: Mammoth::UserCommunity.where(community_id: new_community.id).size,
              created_at: new_community.created_at,
              updated_at: new_community.updated_at
            }
          end
        end

        data = data.sort_by {|h| [h[:is_primary] ? 0 : 1,h[:slug]]}
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
        render json: {message: 'User with community successfully joined!'}
      else
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

    def user_community_params
		  params.require(:user_community).permit(:primary_community, interested_communities: [])
	  end
  end
end