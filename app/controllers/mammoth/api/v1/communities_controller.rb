module Mammoth::Api::V1
	class CommunitiesController < Api::BaseController
		before_action :require_user!, except: %i[index community_bio bio_hashtags people_to_follow editorial_board community_moderators]
		before_action -> { doorkeeper_authorize! :read , :write}, except: %i[index community_bio bio_hashtags people_to_follow editorial_board community_moderators]
		before_action :set_community, only: %i[show update destroy update_is_country_filter_on community_bio bio_hashtags update_community_bio people_to_follow editorial_board community_moderators]

		DEFAULT_TAGS_LIMIT = 10

		def index
			ActiveRecord::Base.connected_to(role: :reading) do

				return return_public_communities if current_user.nil?
				render json: data = Mammoth::CommunityService.new.call_community_details(current_user, current_user_role, params[:collection_id])

			end
		end

		def show
			ActiveRecord::Base.connected_to(role: :reading) do

				if @community.present?
					is_admin = false

					role_name = current_user_role

					is_rss_account = false
					if role_name == "rss-account"
						is_rss_account = true
					end

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
						is_country_filtering: is_rss_account == true ? false : @community.is_country_filtering,
						is_admin: is_admin,
						is_country_filter_on: is_rss_account == true ? false : @community.is_country_filter_on,
						fields: field_datas
					}
				else		
					data = {error: "Record not found"}
				end
				render json: data
			end
		end

		def create
			collection = Mammoth::Collection.find_by(slug: community_params[:collection_id])
			@community = Mammoth::Community.new()
			@community.name = community_params[:name]
			@community.slug = community_params[:slug]
			@community.description = community_params[:description]
			@community.bot_account = community_params[:bot_account]
			@community.bio = community_params[:bio]
			@community.bot_account = community_params[:bot_account]
			@community.bot_account_info = community_params[:bot_account_info]
			@community.guides = community_params[:guides] if community_params[:guides].any?
			@community.collection_id = collection.id
			@community.save

			unless community_params[:image_data].nil?
				image = Paperclip.io_adapters.for(community_params[:image_data])
				@community.image = image
				@community.save
			end
			if @community.save
				render json: @community
			else
				render json: {error: 'community creation failed!'}
			end
		end

		def update
			collection = Mammoth::Collection.find_by(slug: community_params[:collection_id])
			@community.name = community_params[:name]	if community_params[:name].present?
			@community.slug = community_params[:slug]	if community_params[:slug].present?
			@community.position = community_params[:position] if community_params[:position].present?
			@community.description = community_params[:description] if community_params[:description].present?
			@community.is_country_filtering = community_params[:is_country_filtering].present? ? true : false
			@community.is_recommended = community_params[:is_recommended].present? ? true : false
			@community.bio = community_params[:bio] if community_params[:bio].present?
			@community.bot_account = community_params[:bot_account] if community_params[:bot_account].present?
			@community.bot_account_info = community_params[:bot_account_info] if community_params[:bot_account_info].present?
			@community.guides = community_params[:guides] if community_params[:guides].any?

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
			ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do	
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
		end

		def update_is_country_filter_on
			@community.update_attribute(:is_country_filter_on, params[:is_country_filter_on])
      render json: {message: 'Successfully updated'}
		end

		def get_community_follower_list
			query_string = "AND users.account_id < :max_id" if params[:max_id].present?

			community = Mammoth::Community.find_by(slug: params[:id])

			users = User.joins("
				INNER JOIN mammoth_communities_users on mammoth_communities_users.user_id = users.id"
			).where("
				mammoth_communities_users.community_id = :community_id #{query_string}",community_id: community.id, max_id: params[:max_id]).order("users.account_id desc")

			before_limit_statuses = users
			users = users.limit(10)

			account_followed = Follow.where(account_id: current_account).pluck(:target_account_id).map(&:to_i)

      data   = []
      users.each do |user|
        data << {
          account_id: user.account_id.to_s,
          is_followed: account_followed.include?(user.account_id), 
          user_id: user.id.to_s,
          username: user.account.username,
          display_name: user.account.display_name.presence || user.account.username,
          email: user.email,
          image_url: user.account.avatar.url,
          bio: user.account.note,
					acct: user.account.pretty_acct
        }
      end
      render json: {
        data: data,
        meta: {
					pagination:
					{ 
						total_objects: before_limit_statuses.size,
						has_more_objects: 10 <= before_limit_statuses.size ? true : false
					} 
				}
      }
		end

		def get_participants_list
			ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
				community = Mammoth::Community.find_by(slug: params[:id])
				accounts = Rails.cache.read("#{community.slug}-participants")
				if accounts.present?
					accounts = accounts.where("accounts.id < :max_id", max_id: params[:max_id]) if params[:max_id].present?
					accounts = accounts.limit(11)

					render json: accounts.limit(10), root: 'data', 
											each_serializer: Mammoth::AccountSerializer, current_user: current_user, adapter: :json, 
											meta: { 
												has_more_objects: accounts.length > 10 ? true : false
											}
				else
					render json: { data: [] }, status: :ok
				end
			end
		end	
			
		def get_admin_following_list
			ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do	
				community = Mammoth::Community.find_by(slug: params[:id])
				user_ids = Mammoth::CommunityAdmin.where(community_id: community.id).pluck(:user_id)
				account_ids = Mammoth::User.where(id: user_ids).pluck(:account_id)
				followed_accounts = Follow.where(account_id: account_ids).pluck(:target_account_id).uniq
				accounts = Account.left_joins(:user).where(id: followed_accounts).order("id desc")
				accounts = accounts.where("accounts.id < :max_id", max_id: params[:max_id]) if params[:max_id].present?
				accounts = accounts.limit(11)

				render json: accounts.limit(10), root: 'data', 
										each_serializer: Mammoth::AccountSerializer, current_user: current_user, adapter: :json, 
										meta: { 
											has_more_objects: accounts.length > 10 ? true : false
										}
			end						
		end	

		def community_bio 
			render json: @community, serializer: Mammoth::CommunityBioSerializer
		end	

		def bio_hashtags
			tags = Mammoth::CommunityBioService.new.call_bio_hashtag(@community&.id).offset(offset_param).limit(limit_param(DEFAULT_TAGS_LIMIT))

			render json: tags, root: 'data', 
      each_serializer: Mammoth::TagSerializer, current_user: current_user, adapter: :json,
      meta: { 
        has_more_objects: records_continue?(tags),
        offset: offset_param
      }
		end

		def people_to_follow 
			accounts = Mammoth::CommunityBioService.new.call_admin_followed_accounts(@community&.id, current_account&.id)
			return_community_bio_persons(accounts)
		end	

		def editorial_board 
			accounts = Mammoth::CommunityBioService.new.call_editorials_accounts(@community&.id, current_account&.id)
			return_community_bio_persons(accounts)
		end	

		def community_moderators
			accounts = Mammoth::CommunityBioService.new.call_moderator_accounts(@community&.id, current_account&.id)
			return_community_bio_persons(accounts)
		end	

		def update_community_bio
			@community.bio = community_params[:bio] if community_params[:bio].present?
			@community.bot_account = community_params[:bot_account] if community_params[:bot_account].present?
			@community.bot_account_info = community_params[:bot_account_info] if community_params[:bot_account_info].present?
			@community.guides = community_params[:guides] if community_params[:guides].any?
			@community.save

			if @community
				render json: @community
			else
				render json: {error: 'community bio update failed!'}
			end
		end

		private

		def return_public_communities

			data = []

			@collection  = Mammoth::Collection.where(slug: params[:collection_id]).last unless params[:collection_id].nil? 

			@communities = Mammoth::Community.joins("
				LEFT JOIN mammoth_communities_users ON mammoth_communities_users.community_id = mammoth_communities.id"
				)
				.select("mammoth_communities.*,COUNT(mammoth_communities_users.id) as follower_counts")
				.order("mammoth_communities.position ASC,mammoth_communities.name ASC")
				.group("mammoth_communities.id").get_public_communities(@collection)

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
					is_recommended: community.is_recommended
				}
			end

			if params[:collection_id].nil?
				render json: data
			else
				render json: {data: data,
					collection_data:{
						collection_image_url: @collection.image.url,
						collection_name: @collection.name
					}
				}
			end
			
		end

		def return_community
			render json: @community
		end

		def return_community_bio_persons(accounts) 
			accounts = accounts.where("accounts.id < :max_id", max_id: params[:max_id]) if params[:max_id].present?
			render json: accounts.limit(10), root: 'data', 
											each_serializer: Mammoth::AccountSerializer, current_user: current_user, adapter: :json, 
											meta: { 
												has_more_objects: accounts.length > 10 ? true : false
											}
		end

		def offset_param
      params[:offset].to_i
    end

    def records_continue?(records)
      records.size == limit_param(DEFAULT_TAGS_LIMIT)
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
				:is_recommended,
				:bot_account,
				:bio,
				:bot_account_info,
				fields: [:name, :value],
        fields_attributes: [:name, :value],
				guides:[:position,:title,:description]
			)
		end
	end
end
