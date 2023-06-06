require 'feedjira'
require 'httparty'

module Mammoth
  class RSSCreatorWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true, retry: 2, dead: true

    def perform(params = {})
      is_callback   = params['is_callback'] == true
      
      if is_callback
        if url = params['rss_feed_url']
          @cid      = params['community_id']
          @cfeed_id = params['feed_id']
          @account  = Account.find(params['account_id'])
          fetch_feed(url)
        end
      else
        # scheduler
        Mammoth::CommunityFeed.where.not(custom_url: nil).where(delete_at: nil).each do |feed|
          @cid      = feed.community_id
          @account  = feed.account
          @cfeed_id = feed.id

          fetch_feed(feed.custom_url)
        end
      end
    end

    private

      def fetch_feed(url)
        xml  = HTTParty.get(url).body
        feed = Feedjira.parse(xml)
        
        feed.entries.to_a.sort_by(&:published).each do |item|
          link = item.try(:url) || item.try(:enclosure_url)
          if item.published >= 10.days.ago.to_date

            next if @account.statuses.find_by(rss_link: link)
          
            title  = item.title rescue ''
            desc   = item.summary rescue ''
            @image = get_image_url(item, link) || item.image rescue ''

            create_status(title, desc, link)
            create_community_status if @status
          end
        end
      rescue => e
        Rails.logger.error "#{e}, URL: #{url}"
      end

      def create_status(title, desc, link)
        begin
          @status = Mammoth::PostStatusService.new.call(
            @account,
            text:              title,
            spoiler_text:      desc,
            rss_link:          link,
            is_rss_content:    true,
            community_feed_id: @cfeed_id
          )
        rescue
          puts 'RSS Feed Status creation failed!'
        end
      end

      def create_community_status
        begin
          @community_status = Mammoth::CommunityStatus.new(status: @status, community_id: @cid)
          if @image
            @community_status.image = URI.open(@image)
          end
          @community_status.save
        rescue
          puts 'RSS Feed CommunityStatus creation failed!'
        end
      end

      def get_image_url(item, link)
        if link.present?
          meta = LinkThumbnailer.generate(link)
          url  = meta&.images&.first&.src
        end
        url
      rescue 
        url = ''
      end

  end
end
