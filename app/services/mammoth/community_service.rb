module Mammoth
  class CommunityService < BaseService

    def call_community_details(current_user, current_user_role, collection_id = nil)
      data = []

      role_name = current_user_role
			is_rss_account = role_name == "rss-account" ? true : false

      if collection_id.nil?

        #Begin::check user have selected community 
        user = Mammoth::User.find(current_user.id)
        user_communities_ids = user&.user_communities.pluck(:community_id).map(&:to_i) || []
        #End::check user have selected community 

        @communities = Mammoth::Community.joins("
                                              LEFT JOIN mammoth_communities_users ON mammoth_communities_users.community_id = mammoth_communities.id"
                                              )
                                              .select("mammoth_communities.*,COUNT(mammoth_communities_users.id) as follower_counts"
                                              )
                                              .order("mammoth_communities.position ASC,mammoth_communities.name ASC")
                                              .group("mammoth_communities.id")

        if user_communities_ids.any?
          primary_community =  user&.user_communities.where(is_primary: true).last
          @communities.each do |community|
            data << {
              id: community.id,
              position: community.position,
              name: community.name,
              slug: community.slug,
              followers: community.follower_counts,
              participants_count: community.participants_count,
              is_country_filtering: is_rss_account == true ? false : community.is_country_filtering,
              is_country_filter_on: is_rss_account == true ? false : community.is_country_filter_on,
              header_url: community.header.url,
              is_joined: user_communities_ids.include?(community.id), 
              is_primary: primary_community.present? ? primary_community.community_id == community.id  : false,
              image_file_name: community.image_file_name,
              image_content_type: community.image_content_type,
              image_file_size: community.image_file_size,
              image_updated_at: community.image_updated_at,
              description: community.description,
              image_url: community.image.url,
              collection_id: community.collection_id,
              created_at: community.created_at,
              updated_at: community.updated_at,
              is_pinned: !MyPin.find_by(pinned_obj: Community.find(community.id), pin_type: 0, account: current_user&.account).nil?,
              is_recommended: community.is_recommended,
              bot_account: community.bot_account
            }
          end
          #render json: data
        else
          @communities.each do |community|
            data << {
              id: community.id,
              position: community.position,
              name: community.name,
              slug: community.slug,
              followers: community.follower_counts,
              participants_count: community.participants_count,
              is_country_filtering: is_rss_account == true ? false : community.is_country_filtering,
              is_country_filter_on: is_rss_account == true ? false : community.is_country_filter_on,
              header_url: community.header.url,
              is_joined: false, 
              is_primary: false,
              image_file_name: community.image_file_name,
              image_content_type: community.image_content_type,
              image_file_size: community.image_file_size,
              image_updated_at: community.image_updated_at,
              description: community.description,
              image_url: community.image.url,
              collection_id: community.collection_id,
              created_at: community.created_at,
              updated_at: community.updated_at,
              is_pinned: !MyPin.find_by(pinned_obj: Community.find(community.id), pin_type: 0, account: current_user&.account).nil?,
              is_recommended: community.is_recommended,
              bot_account: community.bot_account
            }
          end
          #render json: data
        end
      else
        @user_communities = Mammoth::User.find(current_user.id).user_communities
        user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)
        primary_community =  @user_communities.where(is_primary: true).last
        @collection  = Mammoth::Collection.where(slug: collection_id).last
        unless @collection.nil?

          @communities= @collection.communities.joins("
                        LEFT JOIN mammoth_communities_users ON mammoth_communities_users.community_id = mammoth_communities.id"
                        )
                        .select("mammoth_communities.*,COUNT(mammoth_communities_users.id) as follower_counts"
                        )
                        .order("mammoth_communities.position ASC,mammoth_communities.name ASC")
                        .group("mammoth_communities.id")

          @communities.each do |community|
            data << {
              id: community.id,
              position: community.position,
              name: community.name,
              slug: community.slug,
              followers: community.follower_counts,
              participants_count: community.participants_count,
              is_country_filtering: is_rss_account == true ? false : community.is_country_filtering,
              is_country_filter_on: is_rss_account == true ? false : community.is_country_filter_on,
              header_url: community.header.url,
              is_joined: user_communities_ids.include?(community.id), 
              is_primary: primary_community.present? ? primary_community.community_id == community.id  : false,
              image_file_name: community.image_file_name,
              image_content_type: community.image_content_type,
              image_file_size: community.image_file_size,
              image_updated_at: community.image_updated_at,
              description: community.description,
              image_url: community.image.url,
              collection_id: community.collection_id,
              created_at: community.created_at,
              updated_at: community.updated_at,
              is_pinned: !MyPin.find_by(pinned_obj: Community.find(community.id), pin_type: 0, account: current_user&.account).nil?,
              is_recommended: community.is_recommended,
              bot_account: community.bot_account
            }
          end
        end
      end

      return return_value = {
        data: data,
        collection_data:{
          collection_image_url: @collection&.image&.url,
          collection_name: @collection&.name
        }
      }
      
    end
    
  end
end