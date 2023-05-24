module Mammoth::Api::V1
	class CommunitiesController < Api::BaseController
		before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_community, only: %i[show update destroy update_is_country_filter_on]

		def index
			data = []
			if params[:collection_id].nil?

				#Begin::check user have selected community 
				user = Mammoth::User.find(current_user.id)
				user_communities_ids = user&.user_communities.pluck(:community_id).map(&:to_i) || []
				#End::check user have selected community 

      	@communities= Mammoth::Community.joins("
																							LEFT JOIN mammoth_communities_users ON mammoth_communities_users.community_id = mammoth_communities.id"
																							)
																							.select("mammoth_communities.*,COUNT(mammoth_communities_users.id) as follower_counts"
																							)
																							.order("mammoth_communities.position ASC,mammoth_communities.name ASC")
																							.group("mammoth_communities.id")


				if user_communities_ids.any?
					@communities.each do |community|
						data << {
							id: community.id,
							position: community.position,
							name: community.name,
							slug: community.slug,
							followers: community.follower_counts,
							is_country_filtering: community.is_country_filtering,
							is_country_filter_on: community.is_country_filter_on,
							header_url: community.header.url,
							is_joined: user_communities_ids.include?(community.id), 
							image_file_name: community.image_file_name,
							image_content_type: community.image_content_type,
							image_file_size: community.image_file_size,
							image_updated_at: community.image_updated_at,
							description: community.description,
							image_url: community.image.url,
							collection_id: community.collection_id,
							created_at: community.created_at,
							updated_at: community.updated_at
						}
					end
					render json: data
				else
					@communities.each do |community|
						data << {
							id: community.id,
							position: community.position,
							name: community.name,
							slug: community.slug,
							followers: community.follower_counts,
							is_country_filtering: community.is_country_filtering,
							is_country_filter_on: community.is_country_filter_on,
							header_url: community.header.url,
							is_joined: false, 
							image_file_name: community.image_file_name,
							image_content_type: community.image_content_type,
							image_file_size: community.image_file_size,
							image_updated_at: community.image_updated_at,
							description: community.description,
							image_url: community.image.url,
							collection_id: community.collection_id,
							created_at: community.created_at,
							updated_at: community.updated_at
						}
					end
					render json: data
				end
			else
				@user_communities = Mammoth::User.find(current_user.id).user_communities
				user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)
				primary_community =  @user_communities.where(is_primary: true).last
				@collection  = Mammoth::Collection.where(slug: params[:collection_id]).last
				unless @collection.nil?

					@communities= @collection.communities.joins("
												LEFT JOIN mammoth_communities_users ON mammoth_communities_users.community_id = mammoth_communities.id"
												)
												.where("mammoth_communities.id != :primary_community_id", primary_community_id: primary_community.community_id)
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
							is_country_filtering: community.is_country_filtering,
							is_country_filter_on: community.is_country_filter_on,
							header_url: community.header.url,
							is_joined: user_communities_ids.include?(community.id), 
							image_file_name: community.image_file_name,
							image_content_type: community.image_content_type,
							image_file_size: community.image_file_size,
							image_updated_at: community.image_updated_at,
							description: community.description,
							image_url: community.image.url,
							collection_id: community.collection_id,
							created_at: community.created_at,
							updated_at: community.updated_at
						}
					end
					render json: {data: data,
					collection_data:{
						collection_image_url: @collection.image.url,
						collection_name: @collection.name
					}
				}
				else # No record found!
					render json: data
				end
			end
		end

		def show
			if @community.present?
				is_admin = false
				field_datas = []
				if @community.fields.present?
						@community.fields.each do |key, value|
							field_datas << {
								name: value["name"],
								value: get_social_media_fields(value["name"],value["value"])
							}
						end		
				end
				is_admin = Mammoth::CommunityAdmin.where(community_id:@community.id,user_id: current_user.id).exists?
				data = {
					id: @community.id,
					position: @community.position,
					name: @community.name,
					slug: @community.slug,
					image_url: @community.image.url,
					header_url: @community.header.url,
					description: @community.description,
					collection_id: @community.collection_id,
					created_at: @community.created_at,
					updated_at: @community.updated_at,
					is_country_filtering: @community.is_country_filtering,
					is_admin: is_admin,
					is_country_filter_on: @community.is_country_filter_on,
					fields: field_datas
				}
			else		
				data = {error: "Record not found"}
			end
			render json: data
		end

		def create
			collection = Mammoth::Collection.find_by(slug: community_params[:collection_id])
			@community = Mammoth::Community.new()
			@community.name = community_params[:name]
			@community.slug = community_params[:slug]
			@community.description = community_params[:description]
			@community.collection_id = collection.id
			@community.save

			unless community_params[:image_data].nil?
				image = Paperclip.io_adapters.for(community_params[:image_data])
				@community.image = image
				@community.save
			end
			if @community
				render json: @community
			else
				render json: {error: 'community creation failed!'}
			end
		end

		def update
			collection = Mammoth::Collection.find_by(slug: community_params[:collection_id])
			@community.name = community_params[:name]	
			@community.position = community_params[:position] if community_params[:position].present?
			@community.description = community_params[:description]
			@community.is_country_filtering = community_params[:is_country_filtering]
			@community.collection_id = collection.id

			social_media_json = nil
      if community_params[:fields].size == 9
          social_media_json = {
            "0": {
              name: "Website",
              value: community_params[:fields][0][:value].present? ? community_params[:fields][0][:value] : ""
            },
            "1": {
              name: "Twitter",
              value: community_params[:fields][1][:value].present? ? get_social_media_username("Twitter",community_params[:fields][1][:value].strip) : ""
            },
            "2": {
              name: "TikTok",
              value: community_params[:fields][2][:value].present? ? get_social_media_username("TikTok",community_params[:fields][2][:value].strip) : ""
            },
            "3": {
              name: "Youtube",
              value: community_params[:fields][3][:value].present? ? get_social_media_username("Youtube",community_params[:fields][3][:value].strip) : ""
            },
            "4": {
              name: "Linkedin",
              value: community_params[:fields][4][:value].present? ? get_social_media_username("Linkedin",community_params[:fields][4][:value].strip) : ""
            },
            "5": {
              name: "Instagram",
              value: community_params[:fields][5][:value].present? ? get_social_media_username("Instagram",community_params[:fields][5][:value].strip) : ""
            },
            "6": {
              name: "Substack",
              value: community_params[:fields][6][:value].present? ? get_social_media_username("Substack",community_params[:fields][6][:value].strip) : ""
            },
            "7": {
              name: "Facebook",
              value: community_params[:fields][7][:value].present? ? get_social_media_username("Facebook",community_params[:fields][7][:value].strip) : ""
            },
            "8": {
              name: "Email",
              value: community_params[:fields][8][:value].present? ? community_params[:fields][8][:value] : ""
            }
          } 
					@community.fields = social_media_json
			end
			@community.save

			if community_params[:image_data] !=nil &&  community_params[:image_data] !=  "/images/original/missing.png"
				image = Paperclip.io_adapters.for(community_params[:image_data])
				@community.image = image
				@community.save
			else

			end

			if community_params[:header_data] != nil && community_params[:header_data] != "/headers/original/missing.png"
				header_image = Paperclip.io_adapters.for(community_params[:header_data])
				@community.header = header_image
				@community.save
			end

			if @community
				render json: @community
			else
				render json: {error: 'community update failed!'}
			end
		end

		def destroy
			community = Mammoth::Community.find_by(slug: params[:id])
			# get statuses_ids from CommunityStatus
			communities_statuses_ids = Mammoth::CommunityStatus.where(community_id: community.id).pluck(:status_id).map(&:to_i)
			if communities_statuses_ids.any?

				# get created statuses' account_ids from statuses
				created_status_owner_ids = Status.where(id: communities_statuses_ids).pluck(:account_id).map(&:to_i)

				# to delete status count from AccountStat
				created_status_owner_ids.each do |account_id|
					account_stat = AccountStat.find_by(account_id: account_id)
					status_count = account_stat.statuses_count - 1
					account_stat.update_attribute(:statuses_count, status_count)
				end

				# to delete status count from StatusStat (reblog_count, fav_count, reply_count)
				communities_statuses_ids.each do |status_id|
					StatusStat.where(status_id: status_id).destroy_all
				end

				# to delete status_tag join table => only status_ids
				# communities_statuses_ids.each do |status_id|
				# 	Mammoth::StatusTag.where(status_id: status_id).destroy_all
				# end

				Mammoth::CommunityStatus.where(community_id: community.id).destroy_all

				user_communities = Mammoth::UserCommunity.where(community_id: community.id)
				user_communities.each do |user_community|
					if user_community.is_primary == true
						user_community.delete

						change_user_communities = Mammoth::UserCommunity.where.not(community_id: community.id).where(user_id:user_community.user_id).last
						
						if change_user_communities.present?
							change_user_communities.update_attribute(:is_primary, true)
						else
							change_primary_community = Mammoth::Community.where.not(slug: params[:id]).last
							if change_user_communities.present?
								Mammoth::UserCommunity.create!(
									user_id: user_community.user_id,
									community_id: change_primary_community.id,
									is_primary: true
								)
							end
						end
					else
						user_community.destroy
					end
				end

				Status.where(id: communities_statuses_ids).destroy_all

				Mammoth::CommunityAdmin.where(community_id: community.id).destroy_all

				Mammoth::Community.where(slug: params[:id]).destroy_all

				render json: {message: "Deleted successfully."}
			else
				community = Mammoth::Community.where(slug: params[:id]).last

				if community.present?
					community.destroy
				end

				render json: {error: "No record."}
			end

		end

		def get_communities_with_collections 
			data = []

			user = Mammoth::User.find(current_user.id)

			if params[:collection_slugs].present?
				collections  = Mammoth::Collection.where(slug: params[:collection_slugs]).order(position: :ASC)
			else
				collections  = Mammoth::Collection.all.order(position: :ASC)
			end

			user_communities_ids = user&.user_communities.pluck(:community_id).map(&:to_i) || []
			user_primary_community = user&.user_communities.where(is_primary: true).last
			
			if user_primary_community.present?
				user_primary_community_id = user_primary_community.community_id
			else
				user_primary_community_id = 0
			end
			
			collections.each do |collection|
				unless collection.communities.blank?
					# communities = collection.communities.order(position: :ASC)
					communities = collection.communities.joins("
						LEFT JOIN mammoth_communities_users ON mammoth_communities_users.community_id = mammoth_communities.id"
						)
						.select("mammoth_communities.*,COUNT(mammoth_communities_users.id) as follower_counts"
						)
						.order("mammoth_communities.position ASC,mammoth_communities.name ASC")
						.group("mammoth_communities.id")

					community_data = []
					community_joined_count = 0
					is_included_primary_community = false

					communities.each do |community|

						if user_communities_ids.include?(community.id)
							community_joined_count += 1
						end

						if user_primary_community_id == community.id
							is_included_primary_community = true
						end
																		
						community_data << {
							id: community.id,
							position: community.position,
							name: community.name,
							slug: community.slug,
							followers: community.follower_counts,
							is_joined: user_communities_ids.include?(community.id),
							is_primary: user_primary_community_id == community.id,
							image_file_name: community.image_file_name,
							image_content_type: community.image_content_type,
							image_file_size: community.image_file_size,
							image_updated_at: community.image_updated_at,
							description: community.description,
							collection_id: community.collection_id,
							created_at: community.created_at,
							updated_at: community.updated_at,
							is_country_filtering: community.is_country_filtering,
							fields: community.fields,
							header_file_name: community.header_file_name,
							header_content_type: community.image_file_name,
							header_file_size: community.header_file_size,
							header_updated_at: community.header_updated_at,
							is_country_filter_on: community.is_country_filter_on,
							community_image_url: community.image.url,
							community_header_url: community.header.url
						}
					end

					data << {
							collection_id: collection.id,
							is_included_primary_community: is_included_primary_community,
							position: collection.position,
							collection_name: collection.name,
							collection_slug: collection.slug,
							is_joined_all: communities.size == community_joined_count ? true : false,
							communities: community_data
						}
				end
			end
			render json: data
		end

		def update_is_country_filter_on
			@community.update_attribute(:is_country_filter_on, params[:is_country_filter_on])
      render json: {message: 'Successfully updated'}
		end

		private

		def return_community
			render json: @community
		end

		def set_community
			@community = Mammoth::Community.find_by(slug: params[:id])
		end

		def get_social_media_username(name,value)
      case name
      when "Website"
        value
      when "Twitter"
        if (value.include?("https://twitter.com/"))
          username = value.to_s.split('/').last
        else
          username = value
        end
      when "TikTok"
        if (value.include?("https://www.tiktok.com/"))
          username = value.to_s.split('/').last
        else
          username = value
        end
      when "Youtube"
        if (value.include?("https://www.youtube.com/channel/"))
          username = value.to_s.split('/').last
        else
          username = value
        end
      when "Linkedin"
        if (value.include?("https://www.linkedin.com/in/"))
          username = value.to_s.split('/').last
        else
          username = value
        end
      when "Instagram"
        if (value.include?("https://www.instagram.com/"))
          username = value.to_s.split('/').last
        else
          username = value
        end
      when "Substack"
        if (value.include?("substack.com"))
          username = value.to_s.split('/').last
          username = username.to_s.split('.').first
        else
          username = value
        end
      when "Facebook"
        if (value.include?("https://www.facebook.com/"))
          username = value.to_s.split('/').last
        else
          username = value
        end
      when "Email"
        object.value
      end
    end

		def get_social_media_fields(name,value)
			case name
			when "Website"
				value
			when "Twitter"
				value == "" ? "" : "https://twitter.com/"+value
			when "TikTok"
				value == "" ? "" : "https://www.tiktok.com/"+value
			when "Youtube"
				value == "" ? "" : "https://www.youtube.com/channel/"+value
			when "Linkedin"
				value == "" ? "" : "https://www.linkedin.com/in/"+value
			when "Instagram"
				value == "" ? "" : "https://www.instagram.com/"+value
			when "Substack"
				value == "" ? "" : "https://"+value+".substack.com"
			when "Facebook"
				value == "" ? "" : "https://www.facebook.com/"+value  
			when "Email"
				value
			end	
		end

		def community_params
			params.require(:community).permit(
				:name,
				:slug,
				:image_data, 
				:header_data,
				:description, 
				:collection_id,
				:position,
				:is_country_filtering,
				fields: [:name, :value],
        fields_attributes: [:name, :value],
			)
		end
	end
end