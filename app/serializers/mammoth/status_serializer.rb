# frozen_string_literal: true

class Mammoth::StatusSerializer < ActiveModel::Serializer
  include FormattingHelper
  require 'uri'

  attributes :id,:community_id,:community_name,:community_slug,:created_at, :in_reply_to_id, :in_reply_to_account_id,
             :sensitive, :spoiler_text, :visibility, :language, :is_only_for_followers,
             :uri, :url, :replies_count, :reblogs_count,:is_rss_content,:rss_host_url,
             :favourites_count, :edited_at,:image_url,:rss_link,:is_meta_preview,:translated_text,:meta_title

  attribute :favourited, if: :current_user?
  attribute :reblogged, if: :current_user?
  attribute :muted, if: :current_user?
  attribute :bookmarked, if: :current_user?
  attribute :pinned, if: :pinnable?
  has_many :filtered, serializer: REST::FilterResultSerializer, if: :current_user?

  attribute :content, unless: :source_requested?
  attribute :text, if: :source_requested?

  belongs_to :reblog, serializer: Mammoth::StatusSerializer
  belongs_to :application, if: :show_application?
  belongs_to :account, serializer: Mammoth::AccountSerializer

  has_many :ordered_media_attachments, key: :media_attachments, serializer: REST::MediaAttachmentSerializer
  has_many :ordered_mentions, key: :mentions
  has_many :tags
  has_many :emojis, serializer: REST::CustomEmojiSerializer
  has_many :communities, serializer: Mammoth::CommunitySerializer
  has_one :preview_card, key: :card, serializer: REST::PreviewCardSerializer
  has_one :preloadable_poll, key: :poll, serializer: REST::PollSerializer


  def meta_title
    return " " unless object.is_rss_content? && object.local?
    object.text[0, object.text_count.to_i]
  end

  def community_name
    community_status =  Mammoth::CommunityStatus.where(status_id: object.id).last
    if community_status.present? && community_status.community_id.present? 
      community_status.community.name
    else
      ""
    end
  end

  def community_slug
    community_status =  Mammoth::CommunityStatus.where(status_id: object.id).last
    if community_status.present? && community_status.community_id.present? 
      community_status.community.slug
    else
      ""
    end
  end

  def community_id
    community_status =  Mammoth::CommunityStatus.where(status_id: object.id).last
    if community_status.present? && community_status.community_id.present? 
      community_status.community.id
    else
      ""
    end
  end

  def image_url 
    media_attchment = MediaAttachment.where(status_id: object.id).last
    if media_attchment.present?
      media_attchment.file.url
    else
      community_status =  Mammoth::CommunityStatus.where(status_id: object.id).last
      if community_status.present? && community_status.try(:image).present?
        community_status.try(:image).url
      end
    end
  end

  def is_only_for_followers
    object.is_only_for_followers
  end

  def is_rss_content
    object.is_rss_content
  end

  def rss_link 
    if object.is_rss_content
      object.rss_link.presence || get_custom_url
    end
  end

  def rss_host_url
    if object.is_rss_content
      custom_url = get_custom_url
      unless custom_url.empty?
        uri = URI.parse(custom_url)
        uri.host
      else
        uri = URI.parse(object.rss_link)
        uri.host
      end
    end
  end

  def get_custom_url
    @feed ||= Mammoth::CommunityFeed.where(id: object.community_feed_id).last
    unless @feed.nil?
      @feed.custom_url
    else
      ""
    end
  end

  def is_meta_preview
    object.is_meta_preview
  end

  def id
    object.id.to_s
  end

  def in_reply_to_id
    object.in_reply_to_id&.to_s
  end

  def in_reply_to_account_id
    object.in_reply_to_account_id&.to_s
  end

  def current_user?
    !current_user.nil?
  end

  def show_application?
    object.account.user_shows_application? || (current_user? && current_user.account_id == object.account_id)
  end

  def visibility
    # This visibility is masked behind "private"
    # to avoid API changes because there are no
    # UX differences
    if object.limited_visibility?
      'private'
    else
      object.visibility
    end
  end

  def sensitive
    if current_user? && current_user.account_id == object.account_id
      object.sensitive
    else
      object.account.sensitized? || object.sensitive
    end
  end

  def uri
    ActivityPub::TagManager.instance.uri_for(object)
  end

  def content
   # object.text
    status_content_format(object)
  end

  def translated_text
    status_translated_text_format(object)
  end

  def url
    ActivityPub::TagManager.instance.url_for(object)
  end

  def favourited
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].favourites_map[object.id] || false
    else
      current_user.account.favourited?(object)
    end
  end

  def reblogged
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].reblogs_map[object.id] || false
    else
      current_user.account.reblogged?(object)
    end
  end

  def muted
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].mutes_map[object.conversation_id] || false
    else
      current_user.account.muting_conversation?(object.conversation)
    end
  end

  def bookmarked
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].bookmarks_map[object.id] || false
    else
      current_user.account.bookmarked?(object)
    end
  end

  def pinned
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].pins_map[object.id] || false
    else
      object.account.pinned?(object)
      #current_user.account.pinned?(object) 
    end
  end

  def filtered
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].filters_map[object.id] || []
    else
      current_user.account.status_matches_filters(object)
    end
  end

  def pinnable?
    #current_user? &&
    #current_user.account_id == object.account_id &&
    !object.reblog? &&
    %w(public unlisted private).include?(object.visibility)
  end

  def source_requested?
    instance_options[:source_requested]
  end

  def ordered_mentions
    object.active_mentions.to_a.sort_by(&:id)
  end

  class ApplicationSerializer < ActiveModel::Serializer
    attributes :name, :website

    def website
      object.website.presence
    end
  end

  class MentionSerializer < ActiveModel::Serializer
    attributes :id, :username, :url, :acct

    def id
      object.account_id.to_s
    end

    def username
      object.account_username
    end

    def url
      ActivityPub::TagManager.instance.url_for(object.account)
    end

    def acct
      object.account.pretty_acct
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
