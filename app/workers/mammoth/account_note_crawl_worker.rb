module Mammoth
  class AccountNoteCrawlWorker
    include Sidekiq::Worker
    include ActionView::Helpers::TextHelper
    require 'nokogiri'
    require 'uri'
    sidekiq_options queue: 'custom_account_note_crawl', retry: false, dead: true

    def perform(account_id)
      @account_data = Account.where(id: account_id).last 
      
      if @account_data.try(:note).present? 
        check_hashtag
        check_account
      end
    end

    private 

    def check_hashtag 

      # Check if the string contains any HTML tags
      contains_html_tags = /<("[^"]*"|'[^']*'|[^'">])*>/.match?(@account_data.try(:note))

      if contains_html_tags
        @tags = Extractor.extract_hashtags(PlainTextFormatter.new(@account_data.try(:note), false).to_s) 
      else
        @tags = Extractor.extract_hashtags(@account_data.try(:note))
      end
      Tag.find_or_create_by_names(@tags)
    end

    def check_account
      doc = Nokogiri::HTML.parse(@account_data.try(:note))
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