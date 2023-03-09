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
      json_val = nil

      if params[:fields].size == 7
          json_val = {
            "0": {
              name: params[:fields][0][:name],
              value: params[:fields][0][:value]
            },
            "1": {
              name: params[:fields][1][:name],
              value: params[:fields][1][:value]
            },
            "2": {
              name: params[:fields][2][:name],
              value: params[:fields][2][:value]
            },
            "3": {
              name: params[:fields][3][:name],
              value: params[:fields][3][:value]
            },
            "4": {
              name: params[:fields][4][:name],
              value: params[:fields][4][:value]
            },
            "5": {
              name: params[:fields][5][:name],
              value: params[:fields][5][:value]
            },
            "6": {
              name: params[:fields][6][:name],
              value: params[:fields][6][:value]
            }
          } 
        params[:fields_attributes] = json_val
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

      if params[:contributor_role].present? 
        contributor_role = Mammoth::ContributorRole.where(slug: params[:contributor_role]).last 
        @account.contributor_role_id = contributor_role.id
        contributor_role_name = contributor_role.name
        save_flag = true
      end

      if params[:voices].present? 
        @account.voice_id = Mammoth::Voice.where(slug: params[:voices]).last.id
        save_flag = true
      end

      if params[:media].present?
        @account.media_id = Mammoth::Media.where(slug: params[:media]).last.id
        save_flag = true
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

      contributor_roles = Mammoth::ContributorRole.all
      unless contributor_roles.empty?
        contributor_roles.each do |contributor_role|
          contributor_role_data << {
            contributor_role_id: contributor_role.id,
            contributor_role_name: contributor_role.name,
            contributor_role_slug: contributor_role.slug,
            is_checked: current_account.contributor_role_id == contributor_role.id ? true : false
          }
        end
      end
      
      medias = Mammoth::Media.all
      unless medias.empty?
        medias.each do |media|
          media_data << {
            media_id: media.id,
            media_name: media.name,
            media_slug: media.slug,
            is_checked: current_account.media_id == media.id ? true : false
          }
        end
      end

      voices = Mammoth::Voice.all
      unless voices.empty?
        voices.each do |voice|
          voice_data << {
            voice_id: voice.id,
            voice_name: voice.name,
            voice_slug: voice.slug,
            is_checked: current_account.voice_id == voice.id ? true : false
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
      render json: @account, serializer: Mammoth::CredentialAccountSerializer
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
            emoji_flag: country.emoji_flag
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
      is_my_account = current_account.id == account_info.id ? true : false
      account_followed = Follow.where(account_id: current_account.id).pluck(:target_account_id).map(&:to_i)
      
      statuses = Status.where(account_id: account_id, reply: false)
      account_data = single_serialize(account_info, Mammoth::CredentialAccountSerializer)
      render json: statuses,root: 'statuses_data', each_serializer: Mammoth::StatusSerializer,adapter: :json,
      meta:{
      account_data: account_data.merge(:is_my_account => is_my_account, :is_followed => account_followed.include?(account_id.to_i))
      }

    end

    def single_serialize(collection, serializer, adapter = :json)
      ActiveModelSerializers::SerializableResource.new(
        collection,
        serializer: serializer,
        adapter: adapter
        ).as_json
    end

  end
end