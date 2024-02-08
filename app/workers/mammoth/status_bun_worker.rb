module Mammoth
  class StatusBunWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'status_bun_worker', retry: false, dead: true

    def perform(status_id, options)
      status = Mammoth::Status.find(status_id)
      Mammoth::StatusBunService.new.call(status, options)
    end 
  end
end