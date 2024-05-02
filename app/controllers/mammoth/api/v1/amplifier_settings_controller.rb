# frozen_string_literal: true

class Mammoth::Api::V1::AmplifierSettingsController < Api::BaseController
  before_action :require_user!
  before_action :set_setting, only: [:show, :update] # Set the setting for both show and update actions

  def show
    render json: @setting
  end

  def update
    user_id = current_user.id
    user_timeline_settings = Mammoth::UserTimelineSetting.where(user_id: user_id)

    if user_timeline_settings.count > 1
      user_timeline_settings.destroy_all
      @setting = Mammoth::UserTimelineSetting.create(user_id: user_id) 
    end

    @setting.update!(selected_filters: params[:selected_filters])
    
    current_user.account.update_excluded_and_domains_from_timeline_cache
    current_user.account.update_excluded_from_timeline_domains

    render json: @setting
  end

  private

  def set_setting
    @setting = Mammoth::UserTimelineSetting.find_or_initialize_by(user_id: current_user.id)
  end
end

    