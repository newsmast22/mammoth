module Mammoth::Api::V1
	class AppVersionsController < Api::BaseController
		#before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}
		before_action :set_app_version, only: %i[check_version]

		def check_version
			ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
				unless @app_version.nil?
					app_version_history = Mammoth::AppVersionHistory.where(app_version_id: @app_version.id,os_type: params[:os_type]).last
					if app_version_history.present?
						render json: app_version_history
					else
						render json: {error: "Record not found"}, status: 404
					end
				else
					render json: {error: "Record not found"}, status: 404
				end
			end
		end

		private

		def set_app_version
			@app_version = Mammoth::AppVersion.find_by(version_name: params[:current_app_version])
		end

  end
end