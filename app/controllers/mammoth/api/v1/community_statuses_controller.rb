module Mammoth::Api::V1
	class CommunityStatusesController < Api::BaseController
		before_action -> { authorize_if_got_token! :read, :'read:statuses' }, except: [:create, :update, :destroy]
  	before_action -> { doorkeeper_authorize! :write, :'write:statuses' }, only:   [:create, :update, :destroy]
		before_action :require_user!, except: [:show, :context, :link_preview]
    before_action :set_status, only: [:show, :context]
		before_action :set_thread, only: [:create]

		include Authorization

		# This API was originally unlimited, pagination cannot be introduced without
		# breaking backwards-compatibility. Arbitrarily high number to cover most
		# conversations as quasi-unlimited, it would be too much work to render more
		# than this anyway
		CONTEXT_LIMIT = 4_096

		# This remains expensive and we don't want to show everything to logged-out users
		ANCESTORS_LIMIT         = 40
		DESCENDANTS_LIMIT       = 60
		DESCENDANTS_DEPTH_LIMIT = 20

		def context
			ancestors_limit         = CONTEXT_LIMIT
			descendants_limit       = CONTEXT_LIMIT
			descendants_depth_limit = nil
	
			if current_account.nil?
				ancestors_limit         = ANCESTORS_LIMIT
				descendants_limit       = DESCENDANTS_LIMIT
				descendants_depth_limit = DESCENDANTS_DEPTH_LIMIT
			end
	
			ancestors_results   = @status.in_reply_to_id.nil? ? [] : @status.ancestors(ancestors_limit, current_account)
			descendants_results = @status.descendants(descendants_limit, current_account, descendants_depth_limit)
			loaded_ancestors    = cache_collection(ancestors_results, Status)
			loaded_descendants  = cache_collection(descendants_results, Status)
			order_reply_statues_desc = 	loaded_descendants.sort_by{|e| e[:created_at]}
			@context = Context.new(ancestors: loaded_ancestors, descendants: order_reply_statues_desc)
			statuses = [@status] + @context.ancestors + @context.descendants
			render json: @context, serializer: Mammoth::ContextSerializer, relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id)
		end

		def index
			if params[:community_id].present?
				@community = Mammoth::Community.find_by(slug: params[:community_id])
				@statuses = @community&.statuses || []
			else
				@statuses = Mammoth::Status.all
			end
			if @statuses.any?
				render json: @statuses, each_serializer: Mammoth::StatusSerializer
			else
				render json: { error: "no statuses found " }
			end
		end

		def show
      @status = cache_collection([@status], Status).first
      render json: @status, serializer: Mammoth::StatusSerializer
    end

		def create

			role_name = current_user_role

			selected_communities = []
			if community_status_params[:community_ids].present?
				if community_status_params[:community_ids].any?
					selected_communities = Mammoth::Community.where(slug: community_status_params[:community_ids]).pluck(:id)
				end
			end

			if community_status_params[:community_id].present?
				selected_communities = Mammoth::Community.where(slug: community_status_params[:community_id]).pluck(:id)
			end

			save_statuses(selected_communities)

			render json: {message: 'status with community successfully saved!'}
		end

		def get_community_details_profile
			if params[:id] == 'newsmast.social'
				@result = Mammoth::UserCommunitiesService.virtual_user_community_details
			else 
				@result = Mammoth::Community.get_community_info_details(current_user_role,current_user, params[:id])
			end 
		render json: {
			data: @result
		} 
		end

		def get_community_detail_statues

			#Begin::Create UserCommunitySetting
      userCommunitySetting = Mammoth::UserCommunitySetting.where(user_id: current_user.id).last
			
      unless userCommunitySetting.present?
        create_userCommunitySetting()
      end
      #End:Create UserCommunitySetting

			@user = Mammoth::User.find(current_user.id)
			community = Mammoth::Community.find_by(slug: params[:id])

			# Fetch community admin by selected community to exlude muted/blocked
			# A community can have admin (zero or more)
			community_admins = User.joins("LEFT JOIN mammoth_communities_admins ON mammoth_communities_admins.user_id = users.id AND users.is_active = TRUE ").where("mammoth_communities_admins.community_id = #{community.id} OR users.id = #{current_user.id}")

			#begin::check is community-admin
			is_community_admin = false
			user_community_admin = Mammoth::CommunityAdmin.where(user_id: @user.id, community_id: community.id).last
			if user_community_admin.present?
				is_community_admin = true
			end
			#end::check is community-admin
			@user_communities = @user.user_communities
			user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)

			account_followed_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)

			community_statuses = Mammoth::CommunityStatus.where(community_id: community.id)
			unless community_statuses.empty?
				account_followed_ids.push(current_account.id)
				community_statues_ids= community_statuses.pluck(:status_id).map(&:to_i)

				query_string = "AND statuses.id < :max_id" if params[:max_id].present?
				@statuses = Mammoth::Status.where("
								statuses.id IN (:community_statues_ids) AND statuses.reply = :reply #{query_string}",
								community_statues_ids: community_statues_ids, reply: false,max_id: params[:max_id] )

				#@statuses = @statuses.filter_is_only_for_followers(account_followed_ids)
        		#@statuses = @statuses.filter_banned_statuses
				#begin::check is primary community country filter on/off
				unless is_community_admin
					primary_user_community = Mammoth::UserCommunity.where(user_id: current_user.id,is_primary: true).last
					if primary_user_community.present?
						if primary_user_community.community_id == community.id && community.is_country_filtering && community.is_country_filter_on
							#condition: if (is_country_filter_on = true) fetch only same country user's primary-community statuses
							accounts = Mammoth::Account.filter_timeline_with_countries(current_account.country)
							@statuses = @statuses.filter_is_only_for_followers_profile_details(accounts.pluck(:id).map(&:to_i)) unless accounts.blank?
						end
					end
				end
				#end::check is primary community country filter on/off
	
				#begin::muted account post
				muted_accounts = Mute.where(account_id: community_admins.pluck(:account_id))
				@statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
				#end::muted account post

				#begin::blocked account post
				blocked_accounts = Block.where(account_id: community_admins.pluck(:account_id)).or(Block.where(target_account_id: current_account.id))
				unless blocked_accounts.blank?
	
					combined_block_account_ids = blocked_accounts.pluck(:account_id,:target_account_id).flatten
					combined_block_account_ids.delete(current_account.id)
	
					blocked_statuses_by_accounts= Mammoth::Status.where(account_id: combined_block_account_ids)
					blocled_status_ids = @statuses.fetch_all_blocked_status_ids(blocked_statuses_by_accounts.pluck(:id).map(&:to_i))
					@statuses = @statuses.filter_blocked_statuses(blocled_status_ids.pluck(:id).map(&:to_i))
				
				end
				#end::blocked account post

				#begin::deactivated account post
				deactivated_accounts = Account.joins(:user).where('users.is_active = ?', false)
				unless deactivated_accounts.blank?
					deactivated_statuses = @statuses.blocked_account_status_ids(deactivated_accounts.pluck(:id).map(&:to_i))
					deactivated_reblog_statuses =  @statuses.blocked_reblog_status_ids(deactivated_statuses.pluck(:id).map(&:to_i))
					deactivated_statuses_ids = get_integer_array_from_list(deactivated_statuses)
					deactivated_reblog_statuses_ids = get_integer_array_from_list(deactivated_reblog_statuses)
					combine_deactivated_status_ids = deactivated_statuses_ids + deactivated_reblog_statuses_ids
					@statuses = @statuses.filter_blocked_statuses(combine_deactivated_status_ids)
				end
				#end::deactivated account post
	
				@user_community_setting = Mammoth::UserCommunitySetting.find_by(user_id: current_user.id)
      
				if @user_community_setting.nil? || @user_community_setting.selected_filters["is_filter_turn_on"] == false 
					@statuses = @statuses.filter_banned_statuses
					before_limit_statuses = @statuses
					@statuses = @statuses.limit(5)
					return render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
					meta: {
						pagination:
						{ 
							total_objects: before_limit_statuses.size,
							has_more_objects: 5 <= before_limit_statuses.size ? true : false
						} 
					}

				end

				#begin::country filter
				is_country_filter = false
				
				# filter: country_filter_on && selected_country exists
				if @user_community_setting.selected_filters["location_filter"]["selected_countries"].any? && @user_community_setting.selected_filters["location_filter"]["is_location_filter_turn_on"] == true
					accounts = Mammoth::Account.filter_timeline_with_countries(@user_community_setting.selected_filters["location_filter"]["selected_countries"]) 
					is_country_filter = true
				end

				if is_country_filter == true && accounts.blank? == true
					return render json: { data: [],
						meta: {
							pagination:
							{ 
								total_objects: 0,
								has_more_objects: false
							} 
						}
					}
				end
				#end::country filter
				
				#begin:: source filter: contributor_role, voice, media
				accounts = Mammoth::Account.all if accounts.blank?

				accounts = accounts.filter_timeline_with_contributor_role(@user_community_setting.selected_filters["source_filter"]["selected_contributor_role"]) if @user_community_setting.selected_filters["source_filter"]["selected_contributor_role"].present?

				accounts = accounts.filter_timeline_with_voice(@user_community_setting.selected_filters["source_filter"]["selected_voices"]) if @user_community_setting.selected_filters["source_filter"]["selected_voices"].present?

				accounts = accounts.filter_timeline_with_media(@user_community_setting.selected_filters["source_filter"]["selected_media"]) if @user_community_setting.selected_filters["source_filter"]["selected_media"].present?
				#end:: source filter: contributor_role, voice, media

				@statuses = @statuses.filter_timeline_with_accounts(accounts.pluck(:id).map(&:to_i))

				# #begin::community filter
				# if @user_community_setting.selected_filters["communities_filter"]["selected_communities"].present?
				# 	status_tag_ids = Mammoth::CommunityStatus.group(:community_id,:status_id).where(community_id: @user_community_setting.selected_filters["communities_filter"]["selected_communities"]).pluck(:status_id).map(&:to_i)
				# 	@statuses = @statuses.merge(Mammoth::Status.filter_without_community_status_ids(status_tag_ids))
				# end
				# #end::community filter

				before_limit_statuses = @statuses
				@statuses = @statuses.limit(5)

				render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
				meta: {
					pagination:
					{ 
						total_objects: before_limit_statuses.size,
            has_more_objects: 5 <= before_limit_statuses.size ? true : false
					} 
				}
			else
				render json: { data: [],
					meta: {
            pagination:
            { 
							total_objects: 0,
							has_more_objects: false
            } 
          }
				}
			end
		end
		
		def get_recommended_community_detail_statuses

			#Begin::Create UserCommunitySetting
      userCommunitySetting = Mammoth::UserCommunitySetting.where(user_id: current_user.id).last
      unless userCommunitySetting.present?
        create_userCommunitySetting()
      end
      #End:Create UserCommunitySetting

			@user = Mammoth::User.find(current_user.id)
			community = Mammoth::Community.find_by(slug: params[:id])

			community_admins = Mammoth::User.joins("INNER JOIN mammoth_communities_admins ON mammoth_communities_admins.user_id = users.id AND users.is_active = TRUE ").where("mammoth_communities_admins.community_id = #{community.id}")

			unless community_admins.blank?

				community_admin_followed_account_ids = Follow.where(account_id: community_admins.pluck(:account_id).map(&:to_i)).pluck(:target_account_id).map(&:to_i)

				@user = Mammoth::User.find(current_user.id)
				community = Mammoth::Community.find_by(slug: params[:id])

				#begin::check is community-admin
				is_community_admin = false
				user_community_admin= Mammoth::CommunityAdmin.where(user_id: @user.id, community_id: community.id).last
				if user_community_admin.present?
					is_community_admin = true
				end
				#end::check is community-admin

				@user_communities = @user.user_communities
				user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)
	
				account_followed_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
	
				community_statuses = Mammoth::CommunityStatus.where(community_id: community.id)

				unless community_statuses.empty? || !community_admin_followed_account_ids.any?
					account_followed_ids.push(current_account.id)
					community_statues_ids= community_statuses.pluck(:status_id).map(&:to_i)
					#@statuses = Mammoth::Status.blocked_account_status_ids(community_admin_followed_account_ids)

					query_string = "AND statuses.id < :max_id" if params[:max_id].present?
					@statuses = Mammoth::Status.where("
								statuses.account_id IN (:account_ids) AND statuses.reply = :reply #{query_string}",
								account_ids: community_admin_followed_account_ids, reply: false,max_id: params[:max_id] )

					@statuses = @statuses.filter_with_community_status_ids(community_statues_ids)
          @statuses = @statuses.filter_banned_statuses
					#begin::check is primary community country filter on/off [only for end-user]
					unless is_community_admin
						primary_user_community = Mammoth::UserCommunity.find_by(user_id: current_user.id,is_primary: true)
						if primary_user_community.present?
							if primary_user_community.community_id == community.id && community.is_country_filtering && community.is_country_filter_on
								#condition: if (is_country_filter_on = true) fetch only same country user's primary-community statuses
								accounts = Mammoth::Account.filter_timeline_with_countries(current_account.country)
								@statuses = @statuses.filter_is_only_for_followers_profile_details(accounts.pluck(:id).map(&:to_i)) unless accounts.blank?
							end
						end
					end
					#end::check is primary community country filter on/off
		
					#begin::muted account post

					#Combine current user and community admin

					community_admins = community_admins + [@user]

					muted_accounts = Mute.where(account_id: community_admins.pluck(:account_id))
					@statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
					#end::muted account post

					#begin::blocked account post
					blocked_accounts = Block.where(account_id: community_admins.pluck(:account_id)).or(Block.where(target_account_id: current_account.id))
					unless blocked_accounts.blank?
		
						combined_block_account_ids = blocked_accounts.pluck(:account_id,:target_account_id).flatten
						combined_block_account_ids.delete(current_account.id)
		
						blocked_statuses_by_accounts= Mammoth::Status.where(account_id: combined_block_account_ids)
						blocled_status_ids = @statuses.fetch_all_blocked_status_ids(blocked_statuses_by_accounts.pluck(:id).map(&:to_i))
						@statuses = @statuses.filter_blocked_statuses(blocled_status_ids.pluck(:id).map(&:to_i))
					
					end
					#end::blocked account post
	
					#begin::deactivated account post
					deactivated_accounts = Account.joins(:user).where('users.is_active = ?', false)
					unless deactivated_accounts.blank?
						deactivated_statuses = @statuses.blocked_account_status_ids(deactivated_accounts.pluck(:id).map(&:to_i))
						deactivated_reblog_statuses =  @statuses.blocked_reblog_status_ids(deactivated_statuses.pluck(:id).map(&:to_i))
						deactivated_statuses_ids = get_integer_array_from_list(deactivated_statuses)
						deactivated_reblog_statuses_ids = get_integer_array_from_list(deactivated_reblog_statuses)
						combine_deactivated_status_ids = deactivated_statuses_ids + deactivated_reblog_statuses_ids
						@statuses = @statuses.filter_blocked_statuses(combine_deactivated_status_ids)
					end
					#end::deactivated account post

					@user_community_setting = Mammoth::UserCommunitySetting.find_by(user_id: current_user.id)
      
					if @user_community_setting.nil? || @user_community_setting.selected_filters["is_filter_turn_on"] == false 
						@statuses = @statuses.filter_banned_statuses
						before_limit_statuses = @statuses
						@statuses = @statuses.limit(5)
					#@statuses = @statuses.page(params[:page]).per(5)
						return render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
						meta: {
							pagination:
							{ 
								total_objects: before_limit_statuses.size,
								has_more_objects: 5 <= before_limit_statuses.size ? true : false
							} 
						}
					end

					#begin::country filter
					is_country_filter = false
					
					# filter: country_filter_on && selected_country exists
					if @user_community_setting.selected_filters["location_filter"]["selected_countries"].any? && @user_community_setting.selected_filters["location_filter"]["is_location_filter_turn_on"] == true
						accounts = Mammoth::Account.filter_timeline_with_countries(@user_community_setting.selected_filters["location_filter"]["selected_countries"]) 
						is_country_filter = true
					end

					if is_country_filter == true && accounts.blank? == true
						return render json: { data: [],
							meta: {
								pagination:
								{ 
									total_objects: 0,
									has_more_objects: false
								} 
							}
						}	
					end
					#end::country filter
					
					#begin:: source filter: contributor_role, voice, media
					accounts = Mammoth::Account.all if accounts.blank?

					accounts = accounts.filter_timeline_with_contributor_role(@user_community_setting.selected_filters["source_filter"]["selected_contributor_role"]) if @user_community_setting.selected_filters["source_filter"]["selected_contributor_role"].present?

					accounts = accounts.filter_timeline_with_voice(@user_community_setting.selected_filters["source_filter"]["selected_voices"]) if @user_community_setting.selected_filters["source_filter"]["selected_voices"].present?

					accounts = accounts.filter_timeline_with_media(@user_community_setting.selected_filters["source_filter"]["selected_media"]) if @user_community_setting.selected_filters["source_filter"]["selected_media"].present?
					#end:: source filter: contributor_role, voice, media

					@statuses = @statuses.filter_timeline_with_accounts(accounts.pluck(:id).map(&:to_i))

					# #begin::community filter
					# if @user_community_setting.selected_filters["communities_filter"]["selected_communities"].present?
					# 	status_tag_ids = Mammoth::CommunityStatus.group(:community_id,:status_id).where(community_id: @user_community_setting.selected_filters["communities_filter"]["selected_communities"]).pluck(:status_id).map(&:to_i)
					# 	@statuses = @statuses.merge(Mammoth::Status.filter_without_community_status_ids(status_tag_ids))
					# end
					# #end::community filter

					before_limit_statuses = @statuses
					@statuses = @statuses.limit(5)

					#@statuses = @statuses.page(params[:page]).per(5)
					render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
					meta: {
						pagination:
						{ 
							# total_pages: @statuses.total_pages,
							# total_objects: @statuses.total_count,
							# current_page: @statuses.current_page
							total_objects: before_limit_statuses.size,
							has_more_objects: 5 <= before_limit_statuses.size ? true : false
						} 
				}
				else
					render json: { data: [],
						meta: {
							pagination:
							{ 
								total_objects: 0,
            		has_more_objects: false
							} 
						}
					}	
				end	
			else
				render json: { data: [],
					meta: {
            pagination:
            { 
              total_objects: 0,
            		has_more_objects: false
            } 
          }
				}
			end
		end

		def get_community_statues
			
			#Begin::Create UserCommunitySetting
			userCommunitySetting = Mammoth::UserCommunitySetting.where(user_id: current_user.id).last
			unless userCommunitySetting.present?
				create_userCommunitySetting()
			end
			#End:Create UserCommunitySetting

			@user = Mammoth::User.find(current_user.id)
			community = Mammoth::Community.find_by(slug: params[:id])
			#begin::check is community-admin
			is_community_admin = false
			user_community_admin= Mammoth::CommunityAdmin.where(user_id: @user.id, community_id: community.id).last
			if user_community_admin.present?
				is_community_admin = true
			end
			#end::check is community-admin
			@user_communities = @user.user_communities
			user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)

			account_followed_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)

			community_statuses = Mammoth::CommunityStatus.where(community_id: community.id)
			community_followed_user_counts = Mammoth::UserCommunity.where(community_id: community.id).size
			unless community_statuses.empty?
				account_followed_ids.push(current_account.id)
				community_statues_ids= community_statuses.pluck(:status_id).map(&:to_i)
				@statuses = Mammoth::Status.filter_with_community_status_ids(community_statues_ids)
				#@statuses = @statuses.filter_is_only_for_followers(account_followed_ids)

				#begin::check is primary community country filter on/off
				unless is_community_admin
					primary_user_community = Mammoth::UserCommunity.where(user_id: current_user.id,is_primary: true).last
					if primary_user_community.present?
						if primary_user_community.community_id == community.id && community.is_country_filtering && community.is_country_filter_on
							#condition: if (is_country_filter_on = true) fetch only same country user's primary-community statuses
							accounts = Mammoth::Account.filter_timeline_with_countries(current_account.country)
							@statuses = @statuses.filter_is_only_for_followers_profile_details(accounts.pluck(:id).map(&:to_i)) unless accounts.blank?
						end
					end	
				end
				#end::check is primary community country filter on/off
	
				#begin::muted account post
				muted_accounts = Mute.where(account_id: current_account.id)
				@statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
				#end::muted account post
				
				#begin::blocked account post
				blocked_accounts = Block.where(account_id: current_account.id).or(Block.where(target_account_id: current_account.id))
				unless blocked_accounts.blank?
	
					combined_block_account_ids = blocked_accounts.pluck(:account_id,:target_account_id).flatten
					combined_block_account_ids.delete(current_account.id)
	
					blocked_statuses_by_accounts= Mammoth::Status.where(account_id: combined_block_account_ids)
					blocled_status_ids = @statuses.fetch_all_blocked_status_ids(blocked_statuses_by_accounts.pluck(:id).map(&:to_i))
					@statuses = @statuses.filter_blocked_statuses(blocled_status_ids.pluck(:id).map(&:to_i))
				
				end
				#end::blocked account post

				#begin::deactivated account post
				deactivated_accounts = Account.joins(:user).where('users.is_active = ?', false)
				unless deactivated_accounts.blank?
					deactivated_statuses = @statuses.blocked_account_status_ids(deactivated_accounts.pluck(:id).map(&:to_i))
					deactivated_reblog_statuses =  @statuses.blocked_reblog_status_ids(deactivated_statuses.pluck(:id).map(&:to_i))
					deactivated_statuses_ids = get_integer_array_from_list(deactivated_statuses)
					deactivated_reblog_statuses_ids = get_integer_array_from_list(deactivated_reblog_statuses)
					combine_deactivated_status_ids = deactivated_statuses_ids + deactivated_reblog_statuses_ids
					@statuses = @statuses.filter_blocked_statuses(combine_deactivated_status_ids)
				end
				#end::deactivated account post

				@user_community_setting = Mammoth::UserCommunitySetting.find_by(user_id: current_user.id)
      
				if @user_community_setting.nil? || @user_community_setting.selected_filters["is_filter_turn_on"] == false 

					return render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
					meta: { 
						community_followed_user_counts: community_followed_user_counts,
						community_name: community.name,
						community_description: community.description,
						community_url: community.image.url,
						community_header_url: community.header.url,
						community_slug: community.slug,
						is_joined: user_communities_ids.include?(community.id), 
						is_admin: is_community_admin
					}

				end

				#begin::country filter
				is_country_filter = false
				
				# filter: country_filter_on && selected_country exists
				if @user_community_setting.selected_filters["location_filter"]["selected_countries"].any? && @user_community_setting.selected_filters["location_filter"]["is_location_filter_turn_on"] == true
					accounts = Mammoth::Account.filter_timeline_with_countries(@user_community_setting.selected_filters["location_filter"]["selected_countries"]) 
					is_country_filter = true
				end

				if is_country_filter == true && accounts.blank? == true
					return render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
					meta: { 
						community_followed_user_counts: community_followed_user_counts,
						community_name: community.name,
						community_description: community.description,
						community_url: community.image.url,
						community_header_url: community.header.url,
						community_slug: community.slug,
						is_joined: user_communities_ids.include?(community.id), 
						is_admin: is_community_admin
						}
				end
				#end::country filter
				
				#begin:: source filter: contributor_role, voice, media
				accounts = Mammoth::Account.all if accounts.blank?

				accounts = accounts.filter_timeline_with_contributor_role(@user_community_setting.selected_filters["source_filter"]["selected_contributor_role"]) if @user_community_setting.selected_filters["source_filter"]["selected_contributor_role"].present?

				accounts = accounts.filter_timeline_with_voice(@user_community_setting.selected_filters["source_filter"]["selected_voices"]) if @user_community_setting.selected_filters["source_filter"]["selected_voices"].present?

				accounts = accounts.filter_timeline_with_media(@user_community_setting.selected_filters["source_filter"]["selected_media"]) if @user_community_setting.selected_filters["source_filter"]["selected_media"].present?
				#end:: source filter: contributor_role, voice, media

				@statuses = @statuses.filter_timeline_with_accounts(accounts.pluck(:id).map(&:to_i))

				# #begin::community filter
				# if @user_community_setting.selected_filters["communities_filter"]["selected_communities"].present?
				# 	status_tag_ids = Mammoth::CommunityStatus.group(:community_id,:status_id).where(community_id: @user_community_setting.selected_filters["communities_filter"]["selected_communities"]).pluck(:status_id).map(&:to_i)
				# 	@statuses = @statuses.merge(Mammoth::Status.filter_without_community_status_ids(status_tag_ids))
				# end
				# #end::community filter

				render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
				meta: { 
					community_followed_user_counts: community_followed_user_counts,
					community_name: community.name,
					community_description: community.description,
					community_url: community.image.url,
					community_header_url: community.header.url,
					community_slug: community.slug,
					is_joined: user_communities_ids.include?(community.id), 
					is_admin: is_community_admin
					}
			else
				render json: { data: [],
				meta: { 
					community_followed_user_counts: community_followed_user_counts,
					community_name: community.name,
					community_description: community.description,
					community_url: community.image.url,
					community_header_url: community.header.url,
					community_slug: community.slug,
					is_joined: user_communities_ids.include?(community.id),
					is_admin: is_community_admin,
					}
				}
			end
		end

		def get_my_community_statues
			@user_communities = Mammoth::User.find(current_user.id).user_communities
			user_communities_ids  = @user_communities.pluck(:community_id).map(&:to_i)
			if user_communities_ids.any?
				community_statuses = Mammoth::CommunityStatus.where(community_id: user_communities_ids)
				community_followed_user_counts = Mammoth::UserCommunity.where(community_id: user_communities_ids).size
				unless community_statuses.empty?
					community_statues_ids= community_statuses.pluck(:status_id).map(&:to_i)
					@statuses = Status.where(id: community_statues_ids,reply: false).take(10)
					render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, adapter: :json
				else
					render json: { data: []}
				end
			else
				render json: {
					error: "Record not found"
				 }
			end
		end

		def link_preview
			unless params[:url].nil?
				data = LinkThumbnailer.generate("#{params[:url]}")
				render json: data
			else
				render json: {
					error: "Url must be present"
				 }
			end
		end

    private

		def create_userCommunitySetting
      userCommunitySetting = Mammoth::UserCommunitySetting.where(user_id: current_user.id)
      userCommunitySetting.destroy_all
      Mammoth::UserCommunitySetting.create!(
        user_id: current_user.id,
        selected_filters: {
          default_country: current_user.account.country,
          location_filter: {
            selected_countries: [],
            is_location_filter_turn_on: true
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

		def get_integer_array_from_list(obj_list)
      if obj_list.blank?
       return []
      else
        return obj_list.pluck(:id).map(&:to_i)
      end
    end
		
		def set_status
			@status = Status.find(params[:id])
		end

		def set_thread
			@thread = Status.find(community_status_params[:in_reply_to_id]) if community_status_params[:in_reply_to_id].present?
			authorize(@thread, :show?) if @thread.present?
		  rescue ActiveRecord::RecordNotFound, Mastodon::NotPermittedError
			render json: { error: I18n.t('statuses.errors.in_reply_not_found') }, status: 404
		end

		def community_status_params
			params.require(:community_status).permit(
				:community_id,
				:status,
				:image_data,
				:in_reply_to_id,
				:sensitive,
				:spoiler_text,
				:visibility,
				:language,
				:scheduled_at,
				:is_only_for_followers,
				:is_meta_preview,
				media_ids: [],
				community_ids: [],
				poll: [
					:multiple,
					:hide_totals,
					:expires_in,
					options: [],
				]
			)
		end

		def save_statuses(selected_communities)

			image_data_array = save_media_attachments()
			@status = Mammoth::PostStatusService.new.call(
				current_user.account,
				text: community_status_params[:status],
				thread: @thread,
				media_ids: image_data_array,
				sensitive: community_status_params[:sensitive],
				spoiler_text: community_status_params[:spoiler_text],
				visibility: community_status_params[:visibility],
				language: community_status_params[:language],
				scheduled_at: community_status_params[:scheduled_at],
				application: doorkeeper_token.application,
				poll: community_status_params[:poll],
				idempotency: request.headers['Idempotency-Key'],
				with_rate_limit: true,
				is_only_for_followers: community_status_params[:is_only_for_followers],
				is_meta_preview: community_status_params[:is_meta_preview],
			) 

			if image_data_array.any?

				File.delete("#{Time.now.utc.strftime('%m%d%Y%H%M')}.png")
		
			end

			if selected_communities.any?

				# Create mulitple selected communities
				selected_communities.each do |community_id|
					Mammoth::CommunityStatus.find_or_create_by(status_id: @status.id, community_id: community_id)
				end

				# To check text contains filtered keywords 
				# If keywords contains, save record in community filter statuses
				# Assume user selected mulitple community
				create_status_json = {
					'community_id' => selected_communities,
					'is_status_create' => true,
					'status_id' => @status.id,
					'community_filter_keyword_id' => nil,
					'community_filter_keyword_request' => "non"
				}

				Mammoth::CommunityFilterStatusesCreateWorker.perform_async(create_status_json)
			else
				# To check text contains filtered keywords 
				# If keywords contains, save record in community filter statuses
				# Assume user NOT! selected mulitple community
				create_status_json = {
					'community_id' => nil,
					'is_status_create' => true,
					'status_id' => @status.id,
					'community_filter_keyword_id' => nil,
					'community_filter_keyword_request' => "non"
				}
				Mammoth::CommunityFilterStatusesCreateWorker.perform_async(create_status_json)
			end
		

		end

		def save_media_attachments()
			# Assuming `base64_data` contains the Base64-encoded file
			image_data_array = []
			unless community_status_params[:image_data].nil? || community_status_params[:image_data] == ""
				data = community_status_params[:image_data]# code like this  data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAABPUAAAI9CAYAAABSTE0XAAAgAElEQVR4Xuy9SXPjytKm6ZwnUbNyHs7Jc7/VV9bW1WXWi9q
				image_data = Base64.decode64(data['data:image/png;base64,'.length .. -1])
				new_file=File.new("#{Time.now.utc.strftime('%m%d%Y%H%M')}.png", 'wb')
				new_file.write(image_data)
				
				media_attachment_params = {
					file: new_file
				}
				
				@media_attachment = current_account.media_attachments.create!(media_attachment_params)
				image_data_array << @media_attachment.id
			end
			return image_data_array	
		end

  end
end