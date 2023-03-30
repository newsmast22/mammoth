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
          @cid     = params['community_id']
          @account = Account.find(params['account_id'])
          fetch_feed(url)
        end
      else
        # scheduler
        Mammoth::CommunityFeed.where.not(custom_url: nil).each do |feed|
          @cid     = feed.community_id
          @account = feed.account

          fetch_feed(feed.custom_url)
        end
      end
    end

    private

      def fetch_feed(url)
        xml  = HTTParty.get(url).body
        feed = Feedjira.parse(xml)
        feed.entries.each do |item|
          link = item.url
        
          next if @account.statuses.find_by(rss_link: link)
        
          title = item.title rescue ''
          desc  = item.summary rescue ''
          @image = item.image rescue ''

          create_status(title, desc, link)
          create_community_status if @status
        end
      end

      def create_status(title, desc, link)
        begin
          @status = Mammoth::PostStatusService.new.call(
            @account,
            text:           title,
            spoiler_text:   desc,
            rss_link:       link,
            is_rss_content: true,
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

  end
end
