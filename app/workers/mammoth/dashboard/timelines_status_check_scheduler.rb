# frozen_string_literal: true
module Mammoth
  class Dashboard::TimelinesStatusCheckScheduler
    include Sidekiq::Worker

    sidekiq_options retry: 0

    # If there are enormous records left to crawl images,
    # dispatching many jobs every five minutes will overwhelm the server, 
    # so only enqueue when the queue is empty.
    MAX_PULL_SIZE = 1
    
    def perform
      return if Sidekiq::Queue.new('timelines_status_check_scheduler').size >= MAX_PULL_SIZE

      workers = Sidekiq::Workers.new
      if workers.count > 0
        workers.each do |process_id, thread_id, worker|
          return if worker['queue'] == 'timelines_status_check_scheduler'
        end
      end
      Mammoth::Dashboard::TimelinesStatusCheckService.new.call()
    end
  end
end

