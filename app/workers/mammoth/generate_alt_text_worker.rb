module Mammoth
    class GenerateAltTextWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'generate_alt_text', retry: false, dead: true
  
        def perform(media_attachment_id)
            @media_attachment = Mammoth::MediaAttachment.find(media_attachment_id)
            if @media_attachment.present?
                if @media_attachment.can_generate_alt? 
                    Mammoth::AfterUploadImageService.new(media_attachment_id).call
                else
                    puts "can not generate it  #{@media_attachment.to_json}"
                end
            end
        end
    end
end