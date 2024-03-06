class Mammoth::CommunityBioSerializer < ActiveModel::Serializer

  attributes :id, :slug, :name,:bot_account,:bot_account_id, :bio, :bot_account_info, :guides

  def guides
    object.guides&.sort_by { |hash| hash["position"] }
  end

  def bot_account
    return nil if object.bot_account.nil?
    "@#{object.bot_account.to_s}@newsmast.community"
  end

  def bot_account_id 
    return nil if object.bot_account.nil?
    Account.where(domain: "newsmast.community", username: object.bot_account).last&.id.to_i
  end

end