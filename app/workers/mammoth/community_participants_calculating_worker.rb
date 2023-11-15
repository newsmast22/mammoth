# frozen_string_literal: true
module Mammoth
  class CommunityParticipantsCalculatingWorker
    include Sidekiq::Worker

    def perform
      Mammoth::CommunityParticipantsCalculatingService.new.call
    rescue ActiveRecord::RecordNotFound
      false
    end
  end
end
