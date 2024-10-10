require 'feedjira'
require 'httparty'
require 'set'


class Mammoth::RSSCreatorService < BaseService
  include DatabaseHelper

  def call (params = {})
    @cid      = params['community_id']
    @cfeed_id = params['feed_id']
    @account  = params['account_id']
    fetch_feed(params['url'])
  end
  
  private

    def fetch_feed(url)
      xml  = HTTParty.get(url).body
      feed = Feedjira.parse(xml)
      fallback_image_url = "https://newsmast-assets.s3.eu-west-2.amazonaws.com/default_fallback_resized.png"
      
      recent_statuses = fetch_recent_rss_statuses
      @status_rss_link_200 = recent_statuses.pluck(:rss_link).to_set
      @status_text_200 = recent_statuses.pluck(:text).to_set

      feed.entries.to_a.sort_by(&:published).each do |item|
        link = item&.url || item&.enclosure_url
        if item.published >= 10.days.ago.to_date
          
          next if is_duplicate?("rss_link", link)
        
          text  = item.title rescue ''
          desc   = item.summary rescue ''
          @image = get_image_url(item, link) || item.image || fallback_image_url
          @community_slug = Mammoth::Community.where(id: @cid).last.slug

          # Check status conent duplication
          @regenerated_text = generate_community_hashtags(text)
          search_text_link = @regenerated_text + " " + link

          next if is_duplicate?('text', search_text_link)

          create_status(text, desc, link)
          create_community_status if @status
          crawl_Link(link) if @status

          @status_rss_link_200.add(link)
          @status_text_200.add(search_text_link)

        end
      end
    rescue StandardError => e
      Rails.logger.error "#{e}, URL: #{url}"
    end

    def create_status(text, desc, link)
      begin

        media_attachment_params = {
          file: URI.open(@image)
        } 

        media_attachment = @account.media_attachments.create!(media_attachment_params)

        @status = PostStatusService.new.call(
          @account,
          text:              @regenerated_text,
          spoiler_text:      "",
          rss_link:          link,
          sensitive:         false, 
          is_rss_content:    true,
          community_feed_id: @cfeed_id,
          community_ids:     [@community_slug],
          media_ids:         [media_attachment.id],
          text_count:        text.blank? ? 0 : text.length
        )
      rescue StandardError => e
        puts "RSS Feed Status creation failed! => error: #{e.inspect}"
      end
    end

    def crawl_Link(link)
      assign_text = @status.text
      @status.text = "#{assign_text&.strip} #{link}"
      FetchLinkCardService.new.call(@status)
    rescue ActiveRecord::RecordNotFound
      true
    end

    def generate_community_hashtags(text)
      community_hash_tags = Mammoth::CommunityHashtag
                      .joins(:community)
                      .where(is_incoming: false, community: {slug: @community_slug})

      post = text
      community_hash_tags.each do |community_hash_tag|
        post += " ##{community_hash_tag.hashtag}"
      end
      return text = post
    end

    def create_community_status
      begin
        @community_status = Mammoth::CommunityStatus.find_or_create_by(status: @status, community_id: @cid)
      rescue StandardError
        puts 'RSS Feed CommunityStatus creation failed!'
      end
    end

    def get_image_url(item, link)
      begin
        url = nil
        if link.present?
          meta = LinkThumbnailer.generate(link)
          url  = meta&.images&.first&.src
        end
        url
      rescue StandardError
        url
      end
    end

    def is_duplicate?(attribute, val)
      if attribute == 'rss_link'
        @status_rss_link_200.include?(val)
      elsif attribute == 'text'
        @status_text_200.include?(val)
      end
    end

    def fetch_recent_rss_statuses
      start_date = 1.month.ago.beginning_of_day
      end_date = Date.today.end_of_day
      
      with_read_replica do
      Status.where(is_rss_content: true, reply: false, community_feed_id: @cfeed_id)
      .where(created_at: start_date..end_date)
      .order(created_at: :desc)
      .limit(200)
      end
    end

end