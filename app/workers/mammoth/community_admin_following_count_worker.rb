# frozen_string_literal: true
module Mammoth
  class CommunityAdminFollowingCountWorker
    include Sidekiq::Worker

    def perform(account_id)
      Mammoth::CommunityAdminFollowingCountService.new.call(account_id)
    rescue ActiveRecord::RecordNotFound
      false
    end
  end
end
