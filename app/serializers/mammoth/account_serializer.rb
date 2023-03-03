# frozen_string_literal: true

class Mammoth::AccountSerializer < ActiveModel::Serializer
  include RoutingHelper
  include FormattingHelper

  attributes :id, :username, :acct, :display_name, :locked, :bot, :discoverable,:hide_collections, :group, :created_at,
             :note, :url, :avatar, :avatar_static, :header, :header_static,:primary_community_slug,:primary_community_name,
             :followers_count, :following_count, :statuses_count, :last_status_at,:collection_count,:community_count,
             :country,:country_common_name,:dob

  has_one :moved_to_account, key: :moved, serializer: REST::AccountSerializer, if: :moved_and_not_nested?

  has_many :emojis, serializer: REST::CustomEmojiSerializer

  #has_many :statues,each_serializer: Mammoth::StatusSerializer

  attribute :suspended, if: :suspended?
  attribute :silenced, key: :limited, if: :silenced?
  attribute :noindex, if: :local?

  class FieldSerializer < ActiveModel::Serializer
    include FormattingHelper

    attributes :name, :value, :verified_at

    def value
      object.value
    end
  end

  has_many :fields

  def id
    object.id.to_s
  end

  def country
    if object.country.present?
      object.country
    else
      ""
    end
  end

  def country_common_name
    if object.country.present?
      ISO3166::Country.find_country_by_alpha2(object.country).common_name
    else
      ""
    end
  end

  def dob
    if object.dob.present?
      object.dob
    else
      ""
    end
  end

  def acct
    object.pretty_acct
  end

  def collection_count
    object.user.id
    user  = Mammoth::User.find(object.user.id)
		user_communities= user.user_communities
		count = 0
		unless user_communities.empty?
      ids = user_communities.pluck(:community_id).map(&:to_i)
			collections = Mammoth::Collection.joins(:communities).where(communities: { id: ids }).distinct
      count = collections.size
    else
      count
    end
  end

  def community_count
    @user = Mammoth::User.find(object.user.id)
    @communities = @user&.communities || []
    count = 0
    if @communities.any?
      count = @communities.size
    else
      count
    end
  end

  def primary_community_slug
    user_communities = Mammoth::UserCommunity.where(user_id: object.user.id,is_primary: true).last
    if user_communities.present?
      Mammoth::Community.find(user_communities.community_id).slug
    else
      ""
    end
  end

  def primary_community_name
    user_communities = Mammoth::UserCommunity.where(user_id: object.user.id,is_primary: true).last
    if user_communities.present?
      Mammoth::Community.find(user_communities.community_id).name
    else
      ""
    end
  end

  def note
    object.suspended? ? '' : object.note
  end

  def url
    ActivityPub::TagManager.instance.url_for(object)
  end

  def avatar
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_original_url)
  end

  def avatar_static
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_static_url)
  end

  def header
    full_asset_url(object.suspended? ? object.header.default_url : object.header_original_url)
  end

  def header_static
    full_asset_url(object.suspended? ? object.header.default_url : object.header_static_url)
  end

  def created_at
    object.created_at.midnight.as_json
  end

  def last_status_at
    object.last_status_at&.to_date&.iso8601
  end

  def display_name
    object.suspended? ? '' : object.display_name
  end

  def locked
    object.suspended? ? false : object.locked
  end

  def bot
    object.suspended? ? false : object.bot
  end

  def discoverable
    object.suspended? ? false : object.discoverable
  end

  def hide_collections
    object.suspended? ? false : object.hide_collections
  end

  def moved_to_account
    object.suspended? ? nil : object.moved_to_account
  end

  def emojis
    object.suspended? ? [] : object.emojis
  end

  def fields
    object.suspended? ? [] : object.fields
  end

  def suspended
    object.suspended?
  end

  def silenced
    object.silenced?
  end

  def noindex
    object.user_prefers_noindex?
  end

  delegate :suspended?, :silenced?, :local?, to: :object

  def moved_and_not_nested?
    object.moved? && object.moved_to_account.moved_to_account_id.nil?
  end
end
