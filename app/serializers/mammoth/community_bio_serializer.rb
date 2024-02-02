class Mammoth::CommunityBioSerializer < ActiveModel::Serializer

  attributes :id, :slug, :name,:bot_account, :bio, :bot_account_info, :guides

  def guides
    object.guides&.sort_by { |hash| hash["position"] }
  end

  def bot_account
    return nil if object.bot_account.nil?
    "@#{object.bot_account.to_s}@newsmast.social"
  end

end