class Mammoth::CommunityBioSerializer < ActiveModel::Serializer
  attributes :id, :slug, :name, :bio, :community_hashtags, :bot_account_info, :guides, :people_to_follow

  def community_hashtags
    object.community_hashtags.where(is_incoming: false)
  end

  def guides
    object.guides.sort_by { |hash| hash["position"] }
  end

  def people_to_follow
    people_to_follow = Mammoth::Account.new.get_admin_followed_accounts(object.id, 111605144830233636)
    people_to_follow.map do |account|
      Mammoth::AccountSerializer.new(account).serializable_hash
    end
  end

end