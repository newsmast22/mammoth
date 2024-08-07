module Mammoth::Api::V1
  class UsersController < Api::BaseController
		before_action -> { doorkeeper_authorize! :read , :write}, except: [:get_profile_detail_info_by_account, :get_profile_detail_statuses_by_account, :get_country_list]
    before_action :generate_otp, only: [:change_email_phone]
    before_action :require_user!, except: [:global_suggestion, :get_profile_detail_info_by_account, :get_profile_detail_statuses_by_account, :get_country_list]

    require 'aws-sdk-sns'

    rescue_from ArgumentError do |e|
      render json: { error: e.to_s }, status: 422
    end

    def suggestion
      offset = params[:offset].present? ? params[:offset] : 0
      words = params[:words].present? ? params[:words] : nil

      @accounts = Mammoth::User.users_suggestion(current_user, params[:is_registeration],params[:limit].to_i + 10, offset, words)
        
      render json: @accounts, root: 'data', 
                    each_serializer: Mammoth::AccountSerializer, current_user: current_user, adapter: :json, 
                    meta: { 
                        has_more_objects: records_continue?,
                        offset: offset.to_i
                    }
    end

    def global_suggestion        
      # Assign limit = 5 as 6 if limit is nil
      # Limit always plus one 
      # Addition plus one to get has_more_object

      limit = params[:limit].present? ? params[:limit].to_i + 1 : 6
      offset = params[:offset].present? ? params[:offset] : 0
      keywords = params[:words].present? ? params[:words] : nil

      default_limit = limit - 1

      @accounts = Mammoth::User.search_global_users(limit , offset, keywords, current_account) 

      @accounts = @accounts.take(default_limit) unless keywords.nil?

      render json:  @accounts, root: 'data', 
                    each_serializer: Mammoth::AccountSerializer, current_user: current_user, adapter: :json, 
                    meta: { 
                      has_more_objects: @accounts.size > default_limit ? true : false,
                      offset: offset.to_i
                    }
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
      @user  = Mammoth::User.find(current_user.id)

      if params[:dob].present?
        @account.dob = params[:dob]
        @account.save(validate: false)

        @user.step = "country"
        @user.save(validate: false)
      end

      if params[:country].present?
        @account.country = params[:country]
        @account.save(validate: false)

        @user.step = "communities"
        @user.save(validate: false)

      end
      render json: @account, serializer: Mammoth::CredentialAccountSerializer
    end

    def update_account_sources
      @account = current_account
      contributor_role_name = ""
      voices_name = ""
      media_name = ""
      subtitle_name = ""
      save_flag = false
      about_me_array = []

      if params[:subtitle].present?
        if params[:subtitle] == "none"
          @account.subtitle_id = nil
          subtitle_name = "None"
          save_flag = true
        else
          subtitle =  Mammoth::Subtitle.where(slug: params[:subtitle]).last
          if subtitle.present?
            @account.subtitle_id = subtitle.id  
            subtitle_name = subtitle.name
            save_flag = true
          end
        end
      else # For => params[:contributor_role], params[:voices], params[:media].present?
        @account.update(about_me_title_option_ids: [])
        about_me_array = params[:contributor_role]+ params[:voices] + params[:media]
        save_flag = true 

        if params[:contributor_role].present? 
          contributor_role = Mammoth::AboutMeTitle.find_by(slug: "contributor_roles").about_me_title_options.where(id: params[:contributor_role].first).last 
          contributor_role_name = contributor_role.name
        end

        if params[:voices].present? 
          voices_role = Mammoth::AboutMeTitle.find_by(slug: "voices").about_me_title_options.where(id: params[:voices].first).last 
          voices_name = voices_role.name
        end

        if params[:media].present? 
          media = Mammoth::AboutMeTitle.find_by(slug: "media").about_me_title_options.where(id: params[:media].first).last 
          media_name = media.name
        end
        
        if about_me_array.any?
          @account.about_me_title_option_ids = about_me_array
        end

      end

      if save_flag
        @account.save(validate: false)
        render json: {
          message: 'Successfully saved',
          contributor_role_name: contributor_role_name,
          voices_name: voices_name,
          media_name: media_name,
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
        subtitle_data << {
          subtitle_id: 0,
          subtitle_name: "None",
          subtitle_slug: "none",
          is_checked: current_account.subtitle_id.present? ? false: true
        }
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

    def get_profile_detail_info_by_account
      account = Account.find(params[:id])
      if current_user.nil?
        public_profile_detail(account)
      else
        get_user_details_info(params[:id], account)
      end
    end

    def get_profile_detail_statuses_by_account
      
      current_account_id =  current_user.nil? ? 1 : current_account.id

        if !params[:max_id].nil? || params[:max_id].present? 
          params[:max_id] = Mammoth::Status.new.check_pinned_status(params[:max_id], current_account_id)
        end

        profile_acc = Account.find(params[:id])

        is_account_following = current_user.nil? ? false : current_account.following?(profile_acc)

        statuses = Mammoth::Status.user_profile_timeline(current_account_id ,profile_acc.id, is_account_following, params[:max_id] , page_no = nil )

        render json: statuses,root: 'statuses_data', each_serializer: Mammoth::StatusSerializer,adapter: :json,
        meta:{
          pagination:
            { 
              total_objects: nil,
              has_more_objects: 5 <= statuses.size ? true : false
            } 
        }
  
    end

    def show
      ActiveRecord::Base.connected_to(role: :reading) do

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

        data = {
          do_not_format_note: true
        }

        render json: @account,root: 'data', serializer: Mammoth::CredentialAccountSerializer, data: data ,adapter: :json,
        meta:{
          community_images_url: community_images,
          following_images_url: following_account_images,
          is_admin: is_admin,
          community_slug: community_slug 
        }
      end
    end

    def logout
      Mammoth::NotificationToken.find_by(account_id: current_account.id, notification_token: params[:notification_token], platform_type: params[:platform_type]).destroy if params[:notification_token].present? && params[:platform_type].present?
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

    def change_password
      @user = current_user

      if @user.valid_password?(user_credentail_params[:current_password])
        if user_credentail_params[:new_password] ==  user_credentail_params[:new_password_confirmation]
          @user.update!(password: user_credentail_params[:new_password])
          log_action :change_password, @user
          @user.update_sign_in!(new_sign_in: true)

          sign_in @user

          render json: {message: 'Your Password has been updated!'}
        end
      else
        render json: {error: 'Invalid current password!'}, status: 422
      end
    end

    def change_username
      @account = current_account
      @account.update!(
        username: user_credentail_params[:username]
      )
      render json: {message: 'update successed'}
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationErrorFormatter.new(e, 'account.username': :username, 'invite_request.text': :reason).as_json, status: :unprocessable_entity
    end

    def change_email_phone
      @user = current_user
      phone_no = ""

      if user_credentail_params[:email].present?
        @user.email = user_credentail_params[:email]
        @user.otp_code = @otp_code
      elsif user_credentail_params[:phone].present?

        if (user_credentail_params[:phone].include?("+"))
          phone_no = user_credentail_params[:phone]
        else
          phone_no = "+"+user_credentail_params[:phone]
        end

        domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
        @user.email = "#{phone_no}@#{domain}"
        @user.phone = phone_no
        @user.otp_code = @otp_code
      end

      if @user.save
        Mammoth::Mailer.with(user: @user).account_confirmation.deliver_now if user_credentail_params[:email].present?
        set_sns_publich(phone_no) if phone_no.present?
        render json: {message: 'Successfully updated'}
      else
      render json: {error: @user.errors }, status: 422
      end

    end

    def deactive_account
      @user = current_user

      if @user.valid_password?(user_credentail_params[:current_password])
        if user_credentail_params[:current_password] ==  user_credentail_params[:new_password_confirmation]
          Doorkeeper::AccessToken.where(resource_owner_id: @user.id).destroy_all
          @user = current_user
          @user.update!(is_active: false)
          render json: {message: 'deactivate successed'}
        end
      else
        render json: {error: 'Invalid current password!'}, status: 422
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

    def records_continue?
      @accounts.size == limit_param(10)
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

    def user_credentail_params
      params.require(:user).permit(:current_password, :new_password, :new_password_confirmation,:username,:phone,:email)
    end

    def log_action(action, target)
      Admin::ActionLog.create(
        account: current_account,
        action: :reset_password,
        target: @user
      )
    end

    def public_profile_detail(account_info)
      account_data = single_serialize(account_info, Mammoth::CredentialAccountSerializer)
      render json: {
        data:{
          account_data: account_data.merge(:is_requested => false,:is_my_account => false, :is_followed => false),
          community_images_url: [],
          following_images_url: [],
          is_admin: false,
          community_slug: "",
          account_type: "end-user"
        }
      }
    end

    def get_user_details_info(target_account_id, account_info)
      ActiveRecord::Base.connected_to(role: :reading) do

        role_name = current_user.nil? ? nil : current_user_role

        community_images = []
        following_account_images = []
        is_my_account = current_user.nil? ? false : current_account.id == account_info.id ? true : false

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

        #begin::check account requested or not
        follow_request = Account.requested_map(target_account_id, current_account.id)

        following = Account.following_map(target_account_id, current_account.id)

        is_requested = follow_request.present? ? true : false
        is_following = following.present? ? true : false
        #end::check account requested or not

        account_data = single_serialize(account_info, Mammoth::CredentialAccountSerializer)
        render json: {
          data:{
            account_data: account_data.merge(:is_requested => is_requested,:is_my_account => is_my_account, :is_followed => is_following),
            community_images_url: community_images,
            following_images_url: following_account_images,
            is_admin: is_admin,
            community_slug: community_slug,
            account_type: role_name
          }
        }
      end
    end

    def get_user_details_statuses(account_id, account_info)

      query_string = "AND statuses.id < :max_id" if params[:max_id].present?
      statuses = Mammoth::Status.where("
                statuses.reply = :reply AND statuses.account_id = :account_id #{query_string}",
                reply: false, account_id: account_id, max_id: params[:max_id]
                )      

            
          
      #begin::muted account post
      muted_accounts = Mute.where(account_id: current_account.id)
      statuses = statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
      #end::muted account post

      #begin::blocked account post
      blocked_accounts = Block.where(account_id: current_account.id).or(Block.where(target_account_id: current_account.id))
      unless blocked_accounts.blank?

        combined_block_account_ids = blocked_accounts.pluck(:account_id,:target_account_id).flatten
        combined_block_account_ids.delete(current_account.id)

        blocked_statuses_by_accounts= Mammoth::Status.where(account_id: combined_block_account_ids)
        blocled_status_ids = statuses.fetch_all_blocked_status_ids(blocked_statuses_by_accounts.pluck(:id).map(&:to_i))
        statuses = statuses.filter_blocked_statuses(blocled_status_ids.pluck(:id).map(&:to_i))
      
      end
      #end::blocked account post

      #statuses = statuses.order(created_at: :desc).page(params[:page]).per(5)
      before_limit_statuses = statuses

      status_pins = StatusPin.where(account_id: account_id)

      if status_pins.any?
        statuses = statuses.joins(
          "LEFT JOIN status_pins on statuses.id = status_pins.status_id"
          ).reorder(
            Arel.sql('(case when status_pins.created_at is not null then 1 else 0 end) desc, statuses.id desc')
          ).limit(5)
      else
        statuses = statuses.order(created_at: :desc).limit(5)
      end
      
      render json: statuses,root: 'statuses_data', each_serializer: Mammoth::StatusSerializer,adapter: :json,
      meta:{
        pagination:
          { 
            # total_pages: statuses.total_pages,
            # total_objects: statuses.total_count,
            # current_page: statuses.current_page
            total_objects: before_limit_statuses.size,
            has_more_objects: 5 <= before_limit_statuses.size ? true : false
          } 
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
        get_validated_url(value)
      when "TikTok"
        get_validated_url(value)
      when "Youtube"
        get_validated_url(value)
      when "Linkedin"
        get_validated_url(value)
      when "Instagram"
        get_validated_url(value)
      when "Substack"
        get_validated_url(value)
      when "Facebook"
        get_validated_url(value)
      when "Email"
        object.value
      end
    end

    def get_validated_url(url) 
      begin
        url_path = URI::parse(url).path # => URI::InvalidURIError
      rescue URI::InvalidURIError
        url
      end
    end

    def generate_otp
      @otp_code = (1000..9999).to_a.sample
    end

    def set_sns_publich(phone)
      @client = Aws::SNS::Client.new(
        region: ENV['SMS_REGION'],
        access_key_id: ENV['SMS_ACCESS_KEY_ID'],
        secret_access_key: ENV['SMS_SECRET_ACCESS_KEY']
      )
      @client.set_sms_attributes({
        attributes: { # required
          "DefaultSenderID" => "Newsmast",
          "DefaultSMSType" => "Transactional"
        },
      })
      @client.publish({
        phone_number: phone,
        message: "#{@otp_code} is your Newsmast verification code.", # required
        message_attributes: {
          "String" => {
            data_type: "String", # required
            string_value: "String",
          },
        }
      })
    end

    def get_integer_array_from_list(obj_list)
      if obj_list.blank?
       return []
      else
        return obj_list.pluck(:id).map(&:to_i)
      end
    end

    def perform_accounts_search!
      AccountSearchService.new.call(
        params[:words],
        current_account,
        limit: params[:limit].present? ? params[:limit] : 5 ,
        resolve: true,
        offset: params[:offset].present? ? params[:offset] : 0
      )
    end

    def account_searchable?
      !params[:type].present? && !(params[:words].start_with?('#') || (params[:words].include?('@') && params[:words].include?(' ')))
    end

  end
end
