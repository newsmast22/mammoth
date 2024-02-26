module Mammoth::Api::V1
	class MammothSettingsController < Api::BaseController
		before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
    before_action :set_settings, only: [:index]

		def index 
			ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
				return_setting_json
			end
		end

		def create 
			Mammoth::MammothSetting.where(thing_type: setting_params[:thing_type], thing_type_id: current_account.id).destroy_all
			@setting = Mammoth::MammothSetting.create!(
        thing_type: setting_params[:thing_type],
				thing_type_id: current_account.id,
        settings: setting_params[:settings]
      )
			return_setting_json
		end

		def destroy
			@setting = Mammoth::MammothSetting.find(params[:id]).destroy
			return_setting_json
		end

		private
		
		def set_settings 
			@setting = Mammoth::MammothSetting.where(thing_type: params[:thing_type], thing_type_id: current_account.id).last
		end

		def return_setting_json
			render json: @setting
		end

		def setting_params
			params.require(:mammoth_setting).permit(
				:thing_type,
				settings: [
					:theme,
					:detect_flag
				]
			)
		end


	end
end