module Mammoth
  class RSSCreatorWorker
    include Sidekiq::Worker
    sidekiq_options backtrace: true, retry: 2, dead: true

    def perform(params = {})
      is_callback   = params['is_callback'] == true
      
        if url = params['url'] && is_callback
          params = {
            "community_id"   => params['community_id'],
            "feed_id"        => params['feed_id'],
            "account_id"     => Account.find(params['account_id']),
            "url"            => params['url']
          }

          Mammoth::RSSCreatorService.new.call(params)
        end
    end

  end
end
