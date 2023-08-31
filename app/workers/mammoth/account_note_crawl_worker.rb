module Mammoth
  class AccountNoteCrawlWorker
    include Sidekiq::Worker
    include ActionView::Helpers::TextHelper
    require 'nokogiri'


    sidekiq_options queue: 'custom_account_note_crawl', retry: true, dead: true

    def perform(account_id)
      @account_data = Account.where(id: account_id).last 

      #@account_data = Account.where(id: 110933295158683851).last 
      
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

      # account = account_from_uri(tag['href'])
      # account = ActivityPub::FetchRemoteAccountService.new.call(tag['href'], request_id: @options[:request_id]) if account.nil?
    end

  end
end