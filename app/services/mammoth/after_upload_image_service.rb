# frozen_string_literal: true
module Mammoth
  class AfterUploadImageService < BaseService
    include RoutingHelper

    def initialize(media_attachment_id)
      @media_attachment = Mammoth::MediaAttachment.find(media_attachment_id)
      @payload = validate_image_url!
      @api_service = AltTextAiApiService.new(payload: @payload) 
    end

    def call
      @media_attachment.can_generate_alt?
      check_api_usage_limit!
      create_image_at_alttext_ai!
      update_image_alt!
    end

    private

    def create_image_at_alttext_ai!
      @alttext_return = @api_service.create_image
    end

    def check_api_usage_limit!
      response_body = @api_service.get_account
      usage_limit = response_body.usage_limit 
      usage = response_body.usage 
      usage < usage_limit
    end

    def update_image_alt!
      @media_attachment.update(auto_generated_description: @alttext_return.alt_text)
    end

    def validate_image_url!
      return nil if @media_attachment.nil?
      { image: { url: full_asset_url(@media_attachment.file.url(:small)) } }
    end
  end
end

