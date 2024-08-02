# frozen_string_literal: true

module Mammoth
  class DraftedStatus < ApplicationRecord
    self.table_name = 'mammoth_drafted_statuses'

    include Paginable

    TOTAL_LIMIT = 300
    DAILY_LIMIT = 25

    belongs_to :account, inverse_of: :mammoth_drafted_statuses
    has_many :media_attachments, inverse_of: :mammoth_drafted_status, dependent: :nullify

    validate :validate_total_limit
    validate :validate_daily_limit

    private

    def validate_total_limit
      errors.add(:base, I18n.t('scheduled_statuses.over_total_limit', limit: TOTAL_LIMIT)) if account.mammoth_drafted_statuses.count >= TOTAL_LIMIT
    end

    def validate_daily_limit
      errors.add(:base, I18n.t('scheduled_statuses.over_daily_limit', limit: DAILY_LIMIT)) if account.mammoth_drafted_statuses.where('created_at::date = ?::date', created_at).count >= DAILY_LIMIT
    end
  end
end