# frozen_string_literal: true
module Mammoth
  class Scheduler::RSSCreatorScheduler
    include Sidekiq::Worker
    sidekiq_options retry: 0, lock: :until_executed, lock_ttl: 1.day.to_i

    def perform
      Mammoth::CommunityFeed.where.not(custom_url: nil).where(deleted_at: nil).order(created_at: :desc).each do |feed|
        params = {
          "community_id"   => feed.community_id,
          "feed_id"        => feed.id,
          "account_id"     => feed.account,
          "url"            => feed.custom_url
        }
        Mammoth::RSSCreatorService.new.call(params)
      end
    end

  end
end