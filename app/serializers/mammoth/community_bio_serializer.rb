class Mammoth::CommunityBioSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :id, :slug, :name,:bot_account, :bio, :community_hashtags, :bot_account_info, :guides

  def community_hashtags
    Mammoth::Community.new.get_community_bio_hashtags(instance_options[:tags], current_user.account_id)
  end

  def guides
    object.guides&.sort_by { |hash| hash["position"] }
  end

  def current_user?
    !current_user.nil?
  end

end