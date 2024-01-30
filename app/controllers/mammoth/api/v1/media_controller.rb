# frozen_string_literal: true

class Mammoth::Api::V1::MediaController < Api::BaseController

  def fedi_create
    response = perform_fedi_media_service('create')
    render json: response
  end

  def fedi_update
    response = perform_fedi_media_service('update')
    render json: response
  end

  private 

  def media_attachment_params
    params.permit(:file, :thumbnail, :description, :focus)
  end

  def perform_fedi_media_service(activity_type)
    Federation::MediaActionService.new.call(
      params[:id],
      current_account,
      activity_type: activity_type,
      doorkeeper_token: doorkeeper_token,
      file: media_attachment_params[:file],
      thumbnail: media_attachment_params[:thumbnail],
      description: media_attachment_params[:description],
      focus: media_attachment_params[:focus]
    )
  end
end
