# frozen_string_literal: true

class Mammoth::Api::V1::Community::AmplifierSettingsController < Api::BaseController
  before_action :require_user!
  before_action :set_setting, only: [:show, :update] # Set the setting for both show and update actions

  def show
    render json: @setting
  end

  def update
    user_id = current_user.id
    user_timeline_settings = Mammoth::CommunityAmplifierSettings.where(user_id: user_id, mammoth_community_id: @community.id)
  
    if user_timeline_settings.count > 1
      user_timeline_settings.destroy_all
    end
  
    # Create or update the setting
    @setting = Mammoth::CommunityAmplifierSettings.find_or_initialize_by(user_id: user_id, mammoth_community_id: @community.id)
    @setting.amplifier_setting = params[:amplifier_setting]
    @setting.is_turn_on = @setting.get_amplifier_status
    
    @setting.save
  
    current_user.account.update_excluded_and_domains_from_timeline_cache_by_community(@community.id) if @community&.id
   
    render json: @setting
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Validation failed: Community must exist" }, status: :unprocessable_entity
  end
    

  private

  def set_setting
    @community = Mammoth::Community.find_by(slug: params[:slug])
    @setting = Mammoth::CommunityAmplifierSettings.find_or_initialize_by(user_id: current_user.id, mammoth_community_id: @community.id)
  end
end
  
      