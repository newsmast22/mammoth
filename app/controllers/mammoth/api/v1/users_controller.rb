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
      UpdateAccountService.new.call(@account, account_params, raise_error: true)
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