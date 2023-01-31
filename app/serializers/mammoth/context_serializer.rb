# frozen_string_literal: true

class Mammoth::ContextSerializer < ActiveModel::Serializer
  has_many :ancestors,   serializer: Mammoth::StatusSerializer
  has_many :descendants, serializer: Mammoth::StatusSerializer
end
