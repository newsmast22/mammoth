module Mammoth::Api::V1
  class UsersController < Api::BaseController
		before_action -> { doorkeeper_authorize! :read , :write}
    before_action :require_user!

    def suggestion
      @user  = Mammoth::User.find(current_user.id)
      if params[:limit]
        @users = Mammoth::User.joins(:user_communities).where.not(id: @user.id).where(user_communities: {community_id: @user.communities.ids}).distinct.limit(params[:limit])
      else
        @users = Mammoth::User.joins(:user_communities).where.not(id: @user.id).where(user_communities: {community_id: @user.communities.ids}).distinct
      end
      @users = @users.filter_with_words(params[:words].downcase) if params[:words].present?
      account_followed = Follow.where(account_id: current_account).pluck(:target_account_id).map(&:to_i)
      data   = []
      @users.each do |user|
        data << {
          account_id: user.account_id.to_s,
          is_followed: account_followed.include?(user.account_id), 
          user_id: user.id.to_s,
          username: user.account.username,
          display_name: user.account.display_name.presence || user.account.username,
          email: user.email,
          image_url: user.account.avatar.url,
          bio: user.account.note
        }
      end
      render json: {data: data}
    end

    def global_suggestion
      @user  = Mammoth::User.find(current_user.id)
      if params[:limit]
        @users = Mammoth::User.where.not(id: @user.id).where(role_id: nil).distinct.limit(params[:limit])
      else
        @users = Mammoth::User.where.not(id: @user.id).where(role_id: nil).distinct
      end
      @users = @users.filter_with_words(params[:words].downcase) if params[:words].present?
      account_followed = Follow.where(account_id: current_account).pluck(:target_account_id).map(&:to_i)
      data   = []
      @users.each do |user|
        data << {
          account_id: user.account_id.to_s,
          is_followed: account_followed.include?(user.account_id), 
          user_id: user.id.to_s,
          username: user.account.username,
          display_name: user.account.display_name.presence || user.account.username,
          email: user.email,
          image_url: user.account.avatar.url,
          bio: user.account.note
        }
      end
      render json: {data: data}
    end

    def update
      @account = current_account
      unless params[:avatar].nil?
				image = Paperclip.io_adapters.for(params[:avatar])
        @account.avatar = image
			end
      unless params[:header].nil?
				image = Paperclip.io_adapters.for(params[:header])
        @account.header = image
      end
      social_media_json = nil

      if params[:fields].size == 9
          social_media_json = {
            "0": {
              name: "Website",
              value: params[:fields][0][:value].present? ? params[:fields][0][:value] : ""
            },
            "1": {
              name: "Twitter",
              value: params[:fields][1][:value].present? ? get_social_media_username("Twitter",params[:fields][1][:value].strip) : ""
            },
            "2": {
              name: "TikTok",
              value: params[:fields][2][:value].present? ? get_social_media_username("TikTok",params[:fields][2][:value].strip) : ""
            },
            "3": {
              name: "Youtube",
              value: params[:fields][3][:value].present? ? get_social_media_username("Youtube",params[:fields][3][:value].strip) : ""
            },
            "4": {
              name: "Linkedin",
              value: params[:fields][4][:value].present? ? get_social_media_username("Linkedin",params[:fields][4][:value].strip) : ""
            },
            "5": {
              name: "Instagram",
              value: params[:fields][5][:value].present? ? get_social_media_username("Instagram",params[:fields][5][:value].strip) : ""
            },
            "6": {
              name: "Substack",
              value: params[:fields][6][:value].present? ? get_social_media_username("Substack",params[:fields][6][:value].strip) : ""
            },
            "7": {
              name: "Facebook",
              value: params[:fields][7][:value].present? ? get_social_media_username("Facebook",params[:fields][7][:value].strip) : ""
            },
            "8": {
              name: "Email",
              value: params[:fields][8][:value].present? ? params[:fields][8][:value] : ""
            }
          } 
        params[:fields_attributes] = social_media_json
      end
      UpdateAccountService.new.call(@account, account_params.except(:fields), raise_error: true)
      UserSettingsDecorator.new(current_user).update(user_settings_params) if user_settings_params
      ActivityPub::UpdateDistributionWorker.perform_async(@account.id)
      render json: @account, serializer: Mammoth::CredentialAccountSerializer
    end

    def update_account
      @account = current_account
      unless params[:country].nil? || params[:dob].nil?
        @account.country = params[:country]
        @account.dob = params[:dob]
        @account.save(validate: false)
      end
      render json: @account, serializer: Mammoth::CredentialAccountSerializer
    end

    def update_account_sources
      @account = current_account
      contributor_role_name = ""
      subtitle_name = ""
      save_flag = false
      about_me_array = []

      if params[:contributor_role].present? 
        contributor_role = Mammoth::AboutMeTitle.find_by(slug: "contributor_roles").about_me_title_options.where(id: params[:contributor_role] ).last 
        about_me_array = about_me_array + params[:contributor_role]
        contributor_role_name = contributor_role.name
        save_flag = true
      end

      if params[:voices].present? 
        about_me_array = about_me_array + params[:voices]
        save_flag = true
      end

      if params[:media].present?
        about_me_array = about_me_array + params[:media]
        save_flag = true
      end

      if about_me_array.any?
        @account.about_me_title_option_ids = about_me_array
      end
      

      if params[:subtitle].present?
        subtitle =  Mammoth::Subtitle.where(slug: params[:subtitle]).last
        if subtitle.present?
          @account.subtitle_id = subtitle.id  
          subtitle_name = subtitle.name
          save_flag = true
        end
      end

      if save_flag
        @account.save(validate: false)
        render json: {
          message: 'Successfully saved',
          contributor_role_name: contributor_role_name,
          subtitle_name: subtitle_name
        }
      else
        render json: {error: "Record not found"}
      end      
    end

    def get_source_list
      contributor_role_data = []
      media_data = []
      voice_data = []

      contributor_roles = Mammoth::AboutMeTitle.find_by(slug: "contributor_roles").about_me_title_options.order(:name)
      unless contributor_roles.empty?
        contributor_roles.each do |contributor_role|
          contributor_role_data << {
            contributor_role_id: contributor_role.id,
            contributor_role_name: contributor_role.name,
            contributor_role_slug: contributor_role.slug,
            is_checked: current_account.about_me_title_option_ids.include?(contributor_role.id)
          }
        end
      end
      
      medias = Mammoth::AboutMeTitle.find_by(slug: "media").about_me_title_options.order(:name)
      unless medias.empty?
        medias.each do |media|
          media_data << {
            media_id: media.id,
            media_name: media.name,
            media_slug: media.slug,
            is_checked: current_account.about_me_title_option_ids.include?(media.id)
          }
        end
      end

      voices = Mammoth::AboutMeTitle.find_by(slug: "voices").about_me_title_options.order(:name)
      unless voices.empty?
        voices.each do |voice|
          voice_data << {
            voice_id: voice.id,
            voice_name: voice.name,
            voice_slug: voice.slug,
            is_checked: current_account.about_me_title_option_ids.include?(voice.id)
          }
        end
      end

      if contributor_role_data.any? || media_data.any? || voice_data.any?
        render json: {
          contributor_role: contributor_role_data,
          media: media_data,
          voices: voice_data
        }
      else
        render json: {error: "Record not found"}
      end
    end

    def get_subtitles_list 
      subtitle_data = []
      subtitles = Mammoth::Subtitle.all
      unless subtitles.empty?
        subtitles.each do |subtitle|
          subtitle_data << {
            subtitle_id: subtitle.id,
            subtitle_name: subtitle.name,
            subtitle_slug: subtitle.slug,
            is_checked: current_account.subtitle_id == subtitle.id ? true : false
          }
        end
        render json: subtitle_data
      else
        render json: {error: "Record not found"}
      end
      
    end

    def get_profile_details_by_account
      account = Account.find(params[:id])
      get_user_statuses_info(params[:id], account)
    end

    def show
      @account = current_account
      community_images = []
      following_account_images = []

      #begin::get collection images
      @user  = Mammoth::User.find(current_user.id)
			@user_communities= @user.user_communities
			unless @user_communities.empty?
        community_ids = @user_communities.pluck(:community_id).map(&:to_i)
        communities = Mammoth::Community.where(id: community_ids).take(2)
        communities.each do |community|
					community_images << community.image.url
				end
      end
      #end::get community images

      #begin:get following images
      followed_account_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
      if followed_account_ids.any?

        Account.where(id: followed_account_ids).take(2).each do |following_account|
					following_account_images << following_account.avatar.url
				end
      end
      #end:get following images

      #begin::check community admin & communnity_slug
      is_admin = false
      community_slug = ""
      community_admin = Mammoth::CommunityAdmin.where(user_id: current_user.id).last
      if community_admin.present?
        is_admin = true
        community_slug = community_admin.community.slug
      end
      #end::check community admin & communnity_slug

      render json: @account,root: 'data', serializer: Mammoth::CredentialAccountSerializer,adapter: :json,
      meta:{
        community_images_url: community_images,
        following_images_url: following_account_images,
        is_admin: is_admin,
        community_slug: community_slug 
      }
    end

    def logout
      Doorkeeper::AccessToken.where(token: doorkeeper_token.token).last.destroy
      render json: {message: 'logout successed'}
    end

    def get_country_list
      countries = ISO3166::Country.all
      data = []
      unless countries.empty?
        countries.each do |country|
          data << {
            alpha2: country.alpha2,
            common_name: country.common_name,
            emoji_flag: country.emoji_flag,
            country_code: country.country_code
          }
        end
        render json: data
      else
        render json: data
      end
    end

    private

    def account_params
      params.permit(
        :display_name,
        :note,
        :avatar,
        :header,
        :locked,
        :bot,
        :discoverable,
        :hide_collections,
        :country,
        :dob,
        fields: [:name, :value],
        fields_attributes: [:name, :value]
      )
    end

    def user_settings_params
      return nil if params[:source].blank?
  
      source_params = params.require(:source)
  
      {
        'setting_default_privacy' => source_params.fetch(:privacy, @account.user.setting_default_privacy),
        'setting_default_sensitive' => source_params.fetch(:sensitive, @account.user.setting_default_sensitive),
        'setting_default_language' => source_params.fetch(:language, @account.user.setting_default_language),
      }
    end

    def get_user_statuses_info(account_id, account_info)
      community_images = []
      following_account_images = []
      is_my_account = current_account.id == account_info.id ? true : false
      account_followed_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
      
      statuses = Mammoth::Status.filter_is_only_for_followers_profile_details(account_id)
      statuses = statuses.filter_is_only_for_followers(account_followed_ids)

      #begin::get collection images
      @user  = Mammoth::User.find(current_user.id)
			@user_communities= @user.user_communities
			unless @user_communities.empty?
        community_ids = @user_communities.pluck(:community_id).map(&:to_i)
        communities = Mammoth::Community.where(id: community_ids).take(2)
        communities.each do |community|
					community_images << community.image.url
				end
      end
      #end::get community images

      #begin:get following images
      followed_account_ids = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
      if followed_account_ids.any?

        Account.where(id: followed_account_ids).take(2).each do |following_account|
					following_account_images << following_account.avatar.url
				end
      end
      #end:get following images

      #begin::check community admin & communnity_slug
      is_admin = false
      community_slug = ""
      community_admin = Mammoth::CommunityAdmin.where(user_id: current_user.id).last
      if community_admin.present?
        is_admin = true
        community_slug = community_admin.community.slug
      end
      #end::check community admin & communnity_slug

      account_data = single_serialize(account_info, Mammoth::CredentialAccountSerializer)
      render json: statuses,root: 'statuses_data', each_serializer: Mammoth::StatusSerializer,adapter: :json,
      meta:{
        account_data: account_data.merge(:is_my_account => is_my_account, :is_followed => account_followed_ids.include?(account_id.to_i)),
        community_images_url: community_images,
        following_images_url: following_account_images,
        is_admin: is_admin,
        community_slug: community_slug 
      }

    end

    def single_serialize(collection, serializer, adapter = :json)
      ActiveModelSerializers::SerializableResource.new(
        collection,
        serializer: serializer,
        adapter: adapter
        ).as_json
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

  end
end