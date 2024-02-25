require 'feedjira'
require 'httparty'

class Mammoth::RSSCreatorService < BaseService
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
      
      feed.entries.to_a.sort_by(&:published).each do |item|
        link = item.try(:url) || item.try(:enclosure_url)
        if item.published >= 10.days.ago.to_date
          
          next if is_rss_link_exists?(link)
        
          text  = item.title rescue ''
          desc   = item.summary rescue ''
          @image = get_image_url(item, link) || item.image || fallback_image_url
          @community_slug = Mammoth::Community.where(id: @cid).last.slug

          # Check status conent duplication
          @regenerated_text = generate_comminity_hashtags(text)
          search_text_link = @regenerated_text +" "+link

          next if is_status_duplicate?(search_text_link)

          create_status(text, desc, link)
          create_community_status if @status
          crawl_Link(link) if @status

        end
      end
    rescue => e
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

    def generate_comminity_hashtags(text)
      @community_ids = Mammoth::Community.where(slug: @community_slug).pluck(:id).to_a.uniq
      community_hash_tags = Mammoth::CommunityHashtag.where(community_id: @community_ids, is_incoming: false)
      post = text
      community_hash_tags.each do |community_hash_tag|
        post += " ##{community_hash_tag.hashtag}"
      end
      return text = post
    end

    def create_community_status
      begin
        @community_status = Mammoth::CommunityStatus.find_or_create_by(status: @status, community_id: @cid)
      rescue
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
      rescue 
        url
      end
    end

    def is_status_duplicate?(text)
      Status.where(is_rss_content: true, reply: false).where("text LIKE ?", "%#{text}%").limit(1).exists?
    end

    def is_rss_link_exists?(link)
      Status.where(is_rss_content: true, reply: false).where("rss_link LIKE ?", "%#{link}%").limit(1).exists?
    end

end