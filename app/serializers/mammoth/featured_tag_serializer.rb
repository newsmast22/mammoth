# frozen_string_literal: true

class Mammoth::FeaturedTagSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :id, :name, :url, :statuses_count, :last_status_at

  def id
    object.id.to_s
  end

  def url

    # Begin::orignal_code
    #short_account_tag_url(object.account, object.tag)
    # End::original_code

    #Begin::MKK's modified_code
    tagged_url_str = tag_url(object.tag).to_s
    tagged_url_str.gsub("/tags/", "/api/v1/tag_timelines/")
    #End::MKK's modified_code
  end

  def name
    object.display_name
  end

  def statuses_count
    object.statuses_count.to_s
  end

  def last_status_at
    object.last_status_at&.to_date&.iso8601
  end
end
