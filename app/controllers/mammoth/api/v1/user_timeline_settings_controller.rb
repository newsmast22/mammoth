module Mammoth::Api::V1
	class UserTimelineSettingsController < Api::BaseController
    before_action -> { doorkeeper_authorize! :read , :write}
    before_action :require_user!
		before_action :set_user_timeline_setting, only: %i[index]

    def index
      if @user_timeline_setting.nil?
       render json:{data: []} 
      else
        render json: {data:@user_timeline_setting}
      end
      
    end

    def create
      Mammoth::UserTimelineSetting.where(user_id: current_user.id).destroy_all
      user_timeline_setting_params[:selected_filters][:default_country] << current_user.account.country
      Mammoth::UserTimelineSetting.create!(
        user_id: current_user.id,
        selected_filters: user_timeline_setting_params[:selected_filters]
      )
      render json: {message: 'Successfully created'}
    end

    private

		def set_user_timeline_setting
			@user_timeline_setting = Mammoth::UserTimelineSetting.find_by(user_id: current_user.id)
		end

		def user_timeline_setting_params
			params.require(:user_timeline_setting).permit(
        selected_filters: [
        :is_filter_turn_on,
        :default_country,
          location_filter:[
            :is_location_filter_turn_on,
            selected_countries: []
          ],
          source_filter:[
            :selected_contributor_role,
            :selected_media,
            :selected_voices
          ]
        ]
      )
		end

  end
end