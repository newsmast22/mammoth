module Mammoth
  class AccountNoteCrawlWorker
    include Sidekiq::Worker
    include ActionView::Helpers::TextHelper
    include FormattingHelper
    require 'nokogiri'
    require 'uri'

    sidekiq_options queue: 'custom_account_note_crawl', retry: false, dead: true

    def perform(account_id)
      @account_data = Account.where(id: account_id).last 
      
      if @account_data.try(:note).present? 
        formated_note = account_bio_format(@account_data)
        check_hashtag(formated_note)
        check_account(formated_note)
      end
    end

    private 

    def check_hashtag(note)

      # Check if the string contains any HTML tags
      contains_html_tags = /<("[^"]*"|'[^']*'|[^'">])*>/.match?(note)

      if contains_html_tags
        @tags = Extractor.extract_hashtags(PlainTextFormatter.new(note, false).to_s) 
      else
        @tags = Extractor.extract_hashtags(note)
      end
      Tag.find_or_create_by_names(@tags)
    end

    def check_account(note)
      doc = Nokogiri::HTML.parse(note)
      href_values = doc.css('a.u-url.mention').map { |a| a['href'] }

      href_values.each do |href_value|
        uri = URI.parse(href_value)
        domain = uri.host
        username = uri.path.split('/').last
        url = "https://#{domain}/users/#{username[1..-1]}"
        account = ActivityPub::TagManager.instance.uri_to_resource(url, Account)
        account = ActivityPub::FetchRemoteAccountService.new.call(url, request_id: true) if account.nil?
      end
    end

  end
end