class Mammoth::TagSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :id, :name, :url, :history, :post_count

  attribute :following, if: :current_user?

  def url
    # Begin::orignal_code
    #tag_url(object)
    # End::original_code

    #Begin::MKK's modified_code
    tagged_url_str = tag_url(object).to_s
    tagged_url_str.gsub("/tags/", "/api/v1/tag_timelines/")
    #End::MKK's modified_code
  end

  def post_count
    0
    #object.statuses.count
  end

  def name
    object.display_name
  end

  def following
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].following_map[object.id] || false
    else
      TagFollow.where(tag_id: object.id, account_id: current_user.account_id).exists?
    end
  end

  def current_user?
    !current_user.nil?
  end
end