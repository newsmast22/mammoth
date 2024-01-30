# frozen_string_literal: true

class Mammoth::Api::V1::MediaController < Api::BaseController
  before_action :set_media_attachment, except: [:fedi_create]

  def fedi_create
    response = perform_fedi_media_service('create')
    render json: response
  end

  private 

  def set_media_attachment
    @media_attachment = MediaAttachment.find(params[:id])
  end

  def media_attachment_params
    params.permit(:file, :thumbnail, :description, :focus)
  end

  def perform_fedi_media_service(activity_type)
    Federation::MediaActionService.new.call(
      nil,
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
