# frozen_string_literal: true

class Mammoth::DraftedStatusSerializer < ActiveModel::Serializer
  attributes :id, :params

  has_many :media_attachments, serializer: REST::MediaAttachmentSerializer

  def id
    object.id.to_s
  end

  def params
    object.params.without(:application_id)
  end
end
