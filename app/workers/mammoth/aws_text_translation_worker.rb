module Mammoth
  class AwsTextTranslationWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'aws_translate__text', retry: false, dead: true

    def perform(status_id)
      puts "====================== AwsTextTranslationWorker status_id: #{status_id} ======================"
      # Fetch status_details by status_id
      @status = Status.find_by(id: status_id.to_i)
      puts "==============================  @status: #{@status.inspect} =============================="

      unless !@status.present? || @status.try(:text).nil? || @status.try(:text).blank?
        call_translate_text_service
      end
    end

    private 

    def call_translate_text_service 
      puts "====================== (before tranlate) status_id: #{ @status.id }  |  Text: #{ @status.try(:text) }========================"
      aws_lamda_service = Mammoth::AwsLamdaTranslateService.new
      translated_text = aws_lamda_service.translate_text(@status.text)
      if translated_text.code == 200
        puts "====================== translated_text: #{ translated_text.inspect } ========================"
        unless translated_text["body"]["original_language"].nil? || translated_text["body"]["original_language"] == "en"
          @status.update_columns(language: translated_text["body"]["original_language"], translated_text: translated_text["body"]["translated_text"])
          puts "====================== (after tranlate) status_id: #{ @status.id }  |  translated_text: #{ @status.try(:translated_text) } ========================"
          return true if @status
        end
      end
    end
      
  end
end