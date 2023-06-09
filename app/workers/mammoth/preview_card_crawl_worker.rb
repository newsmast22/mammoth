
module Mammoth
  class PreviewCardCrawlWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true, retry: 0
    
    def perform
      preview_cards = PreviewCard.where(image_file_name: nil).where("retry_count < 3")
      preview_cards.each do |preview_card|
        url = preview_card.url
        if image_url=get_image_url(url)
          begin
            preview_card.image = URI.open(image_url)
            preview_card.save
          rescue => e
            Rails.logger.info "Failed to save image: #{e}"
          end
        end
        preview_card.retry_count += 1
        preview_card.save
      end
    end

      private

      def get_image_url(link)
        begin
          url = nil
          if link.present?
            fallback_image_url = "https://newsmast-assets.s3.eu-west-2.amazonaws.com/default_fallback_resized.png"
            meta = LinkThumbnailer.generate(link)
            image_url  = meta&.images&.first&.src
            unless image_url.blank?
              url = image_url
            else 
              url = fallback_image_url
            end
          end
          url
        rescue 
          url
        end
      end
    
  end
end