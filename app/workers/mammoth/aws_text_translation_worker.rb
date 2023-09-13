module Mammoth
  class AwsTextTranslationWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'translate_text', retry: false, dead: true

    def perform(status_id)
      # Fetch status_details by status_id
      status = Mammoth::Status.where(id: status_id).last

      unless status.nil? || status.try(:text).nil? || status.try(:text).blank?
        aws_lamda_service = Mammoth::AwsLamdaTranslateService.new
        translated_text = aws_lamda_service.translate_text(status.text)
        if translated_text["statusCode"] == 200
          unless translated_text["body"]["original_language"].nil? || translated_text["body"]["original_language"] == "en"
            status.update_columns(language: translated_text["body"]["original_language"], translated_text: translated_text["body"]["translated_text"])
          end
        end
      end
    end
      
  end
end