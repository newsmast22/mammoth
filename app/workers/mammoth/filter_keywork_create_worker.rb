module Mammoth
  class FilterKeyworkCreateWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'filter_keywork_create_worker', retry: false, dead: true

    def perform(keyword_id ,options)
      keyword_obj = Mammoth::CommunityFilterKeyword.where(id: keyword_id).last
      Mammoth::FilterKeywordCreateService.new.call(keyword_obj, options)
    end 
  end
end