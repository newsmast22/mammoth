module Mammoth::Api::V1
	class CommunityAdminSettingsController < Api::BaseController
    before_action -> { doorkeeper_authorize! :read , :write}
    before_action :require_user!
		before_action :set_community_admin_setting, only: %i[index]

    def index
      if @community_admin_setting.nil?
       render json:{data: []} 
      else
        render json: {data:@community_admin_setting}
      end
    end

    def create
      @user = Mammoth::User.find(current_user.id)
      Mammoth::CommunityAdminSetting.create!(
        community_admin_id: @user.community_admins.last.id,
        is_country_filter_on: community_admin_setting_params[:is_country_filter_on]
      )
      render json: {message: 'Successfully created'}
    end

    def update
      @community_admin_setting = Mammoth::CommunityAdminSetting.find(params[:id])
      @community_admin_setting.update_attribute(:is_country_filter_on, community_admin_setting_params[:is_country_filter_on])
      render json: {message: 'Successfully updated'}
    end

    private

		def set_community_admin_setting
      @user = Mammoth::User.find(current_user.id)
			@community_admin_setting = Mammoth::CommunityAdminSetting.find_by(community_admin_id: @user.community_admins.last.id)
		end

		def community_admin_setting_params
			params.require(:community_admin_setting).permit(
        :is_country_filter_on
      )
		end
  end
end