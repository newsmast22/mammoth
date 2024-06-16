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
    
    current_user.update_all_community_amplifier_blocked_bluesky if current_user.is_global_changed_bluesky(params[:selected_filters])
    current_user.update_all_community_amplifier_blocked_thread if current_user.is_global_changed_thread(params[:selected_filters])

    @setting.update!(selected_filters: params[:selected_filters])
    @setting.reload
  
    current_user.account.update_excluded_and_domains_from_timeline_cache
    json_data = current_user.get_user_amplifier_setting
    if json_data&.dig("is_filter_turn_on")
      time_zones = json_data&.dig("home", "time_zones")
      Newsmast::TimelineRegeneratorByTimezones.perform_async("home",current_user.account.id, time_zones)  if time_zones
    end
    render json: @setting
  end

  private

  def set_setting
    @setting = Mammoth::UserTimelineSetting.find_or_initialize_by(user_id: current_user.id)
  end
end

    