# frozen_string_literal: true
module Mammoth
  class CommunityParticipantsCalculatingWorker
    include Sidekiq::Worker

    def perform(slug)
      Mammoth::CommunityParticipantsCalculatingService.new.call(slug)
    rescue ActiveRecord::RecordNotFound
      false
    end
  end
end
