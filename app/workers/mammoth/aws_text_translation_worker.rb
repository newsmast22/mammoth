module Mammoth
  class AwsTextTranslationWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'custom_notificaion', retry: true, dead: true

    def perform(status_id)

      # Fetch status_details by status_id
      status = Mammoth::Status.find(status_id)

      unless status.text.nil? || status.text.blank?
        # Create an AWS Comprehend client
        comprehend_client_response = AwsTextTranslation.new(comprehend_flag: true)
        language_type = comprehend_client_response.comprehend_text(text: status.text.to_s)

        unless language_type == "en" #  [ en => English ]
          # Create an AWS Translate client
          translate_client_response = AwsTextTranslation.new(comprehend_flag: false)
          translated_text = translate_client_response.translate_text(text: status.text.to_s)

          # Update status language if language is not "English"
          status.language = language_type
          status.translated_text = translated_text
          status.save(validate: false)
        end

      end
    end
      
  end
end