module Mammoth
  class AwsTextTranslationWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'translate_text', retry: false, dead: true

    def perform(status_id)
      # Fetch status_details by status_id
      status = Status.where(id: status_id).last
      puts "====================== AwsTextTranslationWorker status_id: #{status_id} ========================"
      unless status.nil? || status.try(:text).nil? || status.try(:text).blank?
        puts "====================== (before tranlate) status_id: #{ status.id }  |  Text: #{ status.try(:text) }========================"
        aws_lamda_service = Mammoth::AwsLamdaTranslateService.new
        translated_text = aws_lamda_service.translate_text(status.text)
        if translated_text.code == 200
          puts "====================== translated_text: #{ translated_text.inspect } ========================"
          unless translated_text["body"]["original_language"].nil? || translated_text["body"]["original_language"] == "en"
            status.update_columns(language: translated_text["body"]["original_language"], translated_text: translated_text["body"]["translated_text"])
            puts "====================== (after tranlate) status_id: #{ status.id }  |  translated_text: #{ status.try(:translated_text) } ========================"
          end
        end
      end
    end
      
  end
end