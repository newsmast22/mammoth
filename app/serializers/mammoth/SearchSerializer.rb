# frozen_string_literal: true
class Mammoth::SearchSerializer < ActiveModel::Serializer
  has_many :accounts, serializer: Mammoth::AccountSerializer
  has_many :statuses, serializer: Mammoth::StatusSerializer
  has_many :hashtags, serializer: Mammoth::TagSerializer
end
