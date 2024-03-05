# frozen_string_literal: true

class Mammoth::CredentialAccountSerializer < Mammoth::AccountSerializer
  attributes :source

  has_one :role, serializer: REST::RoleSerializer
  has_many :tags


  def source
    if object.try(:user).present?
      user = object.user
      {
        privacy: user.setting_default_privacy,
        sensitive: user.setting_default_sensitive,
        language: user.setting_default_language,
        note: object.note,
        fields: object.fields.select { |field| field.value.present? },
        follow_requests_count: FollowRequest.where(target_account: object).limit(40).count,
      }
    end
  end

  def role
    if object.try(:user).present?
      object.user_role
    end
  end

  class TagSerializer < ActiveModel::Serializer
    include RoutingHelper

    attributes :name, :url

    def url
      # Begin::orignal_code
      #tag_url(object)
      # End::original_code

      #Begin::MKK's modified_code
      tagged_url_str = tag_url(object).to_s
      tagged_url_str.gsub("/tags/", "/api/v1/tag_timelines/")
      #End::MKK's modified_code

    end
  end
end
