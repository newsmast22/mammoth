# frozen_string_literal: true

class Mammoth::AccountSerializer < ActiveModel::Serializer
  include RoutingHelper
  include FormattingHelper

  attributes :id,:account_id, :username, :acct, :display_name, :locked, :bot, :discoverable,:hide_collections, :group, :created_at,
             :note, :url, :avatar, :avatar_static, :header, :header_static,:primary_community_slug,:primary_community_name,
             :followers_count, :following_count, :statuses_count, :last_status_at,:collection_count,:community_count,
             :country,:country_common_name,:dob,:subtitle,:about_me,:hash_tag_count,:is_followed,:is_requested,
             :email,:phone,:step,:is_active,:is_account_setup_finished,:domain,:image_url,:bio,:is_popular,:is_recommended
             

  has_one :moved_to_account, key: :moved, serializer: Mammoth::AccountSerializer, if: :moved_and_not_nested?

  has_many :emojis, serializer: REST::CustomEmojiSerializer

  #has_many :statues,each_serializer: Mammoth::StatusSerializer

  attribute :suspended, if: :suspended?
  attribute :silenced, key: :limited, if: :silenced?
  attribute :noindex, if: :local?

  class FieldSerializer < ActiveModel::Serializer
    include FormattingHelper

    attributes :name, :value, :verified_at

    def value
      case object.name
      when "Website"
        object.value
      when "Twitter"
        object.value == "" ? "" : "https://twitter.com"+object.value
      when "TikTok"
        object.value == "" ? "" : "https://www.tiktok.com"+object.value
      when "Youtube"
        object.value == "" ? "" : "https://www.youtube.com"+object.value
      when "Linkedin"
        object.value == "" ? "" : "https://www.linkedin.com"+object.value
      when "Instagram"
        object.value == "" ? "" : "https://www.instagram.com"+object.value
      when "Substack"
        object.value == "" ? "" : "https://substack.com"+object.value
      when "Facebook"
        object.value == "" ? "" : "https://www.facebook.com"+object.value  
      when "Email"
        object.value
      end
    end

  end
  
  has_many :filtered_fields, key: :fields, serializer: FieldSerializer

  def filtered_fields
    object.fields.select { |field| field.value.present? }
  end

  def id
    object.id.to_s
  end

  def image_url
    object.avatar.url&.remove('mammoth/')
  end

  def bio 
    if instance_options && instance_options[:data] && instance_options[:data][:do_not_format_note]
      object.suspended? ? '' : object.note
    else
      object.suspended? ? '' : account_bio_format(object)
    end
  end

  def account_id
    object.id.to_s
  end

  def statuses_count
    ActiveRecord::Base.connected_to(role: :reading) do
      object.statuses.without_replies.count
    end
  end

  def step
    object.try(:user).try(:step)
  end

  def is_active
    object.try(:user).try(:is_active)
  end
  
  def is_account_setup_finished
    object.try(:user).try(:is_account_setup_finished)
  end

  def email
    if object.try(:domain).nil?
      if object.try(:user).try(:phone).present?
        nil
      else
        object.try(:user).try(:email)
      end
    else
      nil
    end
    
  end

  def phone
    if object.try(:domain).nil?
      object.try(:user).try(:phone)
    else
      nil
    end
  end

  def is_followed
    if  @instance_options[:current_user].present?
      account_followed_ids = Follow.where(account_id: @instance_options[:current_user].account.id).pluck(:target_account_id).map(&:to_i)
      account_followed_ids.include?(object.id)
    else
      return false
    end
  end

  def is_requested 
    if  @instance_options[:current_user].present?
      follow_request = FollowRequest.where(account_id: @instance_options[:current_user].account_id, target_account_id: object.id)
      is_requested = follow_request.present? ? true : false 
    else
      return false
    end
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

  def subtitle
    subtitle = Mammoth::Subtitle.where(id: object.subtitle_id).last
    if subtitle.present?
      subtitle.name
    else
      ""
    end
  end

  def domain 
    object.domain
  end

  def hash_tag_count
    TagFollow.where(account: object.id).count
  end

  def about_me
    contributor_role = Mammoth::AboutMeTitle.find_by(slug: "contributor_roles").about_me_title_options.where(id:object.about_me_title_option_ids ).first
    if contributor_role.present?
      contributor_role.name
    else
      about_me_option = ""
      about_me_option = Mammoth::AboutMeTitleOption.where(id: object.about_me_title_option_ids.first).last.name if object.about_me_title_option_ids.present?
      about_me_option
    end
  end

  def collection_count
    if object.try(:user).present?
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
  end

  def community_count
    if object.try(:user).present?
      @user = Mammoth::User.find(object.user.id)
      @communities = @user&.communities || []
      count = 0
      if @communities.any?
        count = @communities.size
      else
        count
      end
    end
  end

  def primary_community_slug
    ActiveRecord::Base.connected_to(role: :reading) do
      if object.try(:user).present?
        user_communities = Mammoth::UserCommunity.where(user_id: object.user.id,is_primary: true).last
        if user_communities.present?
          user_communities&.community&.slug
        else
          ""
        end
      end
    end
  end

  def primary_community_name
    ActiveRecord::Base.connected_to(role: :reading) do
      if object.try(:user).present?
        user_communities = Mammoth::UserCommunity.where(user_id: object.user.id,is_primary: true).last
        if user_communities.present?
          user_communities&.community&.name
        else
          ""
        end
      end
    end
  end

  def note
    if instance_options && instance_options[:data] && instance_options[:data][:do_not_format_note]
      object.suspended? ? '' : object.note
    else
      object.suspended? ? '' : account_bio_format(object)
    end
  end

  def url
    ActivityPub::TagManager.instance.url_for(object)
  end

  def avatar
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_original_url)&.remove('mammoth/')
  end

  def avatar_static
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_static_url)
  end

  def header
    full_asset_url(object.suspended? ? object.header.default_url : object.header_original_url)&.remove('mammoth/')
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
    object.suspended? ? '' : object.display_name.empty? ? object.username : object.display_name
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
