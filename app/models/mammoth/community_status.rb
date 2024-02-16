module Mammoth
  class CommunityStatus < ApplicationRecord
    self.table_name = 'mammoth_communities_statuses'
    include Attachmentable

    belongs_to :community, optional: true
    belongs_to :status

    after_create :boost_bot_status

    scope :filter_out_breaking_news, ->(breaking_news_id) { where.not(community_id: breaking_news_id) }

    IMAGE_LIMIT = 15.megabytes

    IMAGE_MIME_TYPES = %w(image/jpeg image/png image/gif image/heic image/heif image/webp image/avif).freeze

    BLURHASH_OPTIONS = {
      x_comp: 4,
      y_comp: 4,
    }.freeze

    IMAGE_STYLES = {
      original: {
        pixels: 2_073_600, # 1920x1080px
        file_geometry_parser: FastGeometryParser,
      }.freeze,

      small: {
        pixels: 230_400, # 640x360px
        file_geometry_parser: FastGeometryParser
        #blurhash: BLURHASH_OPTIONS,
      }.freeze,
    }.freeze

    IMAGE_CONVERTED_STYLES = {
      original: {
        format: 'jpeg',
        content_type: 'image/jpeg',
      }.merge(IMAGE_STYLES[:original]).freeze,

      small: {
        format: 'jpeg',
      }.merge(IMAGE_STYLES[:small]).freeze,
    }.freeze

    THUMBNAIL_STYLES = {
      original: IMAGE_STYLES[:small].freeze,
    }.freeze

    GLOBAL_CONVERT_OPTIONS = {
      all: '-quality 90 +profile "!icc,*" +set modify-date +set create-date',
    }.freeze

    has_attached_file :image, styles: THUMBNAIL_STYLES,
    processors: [:lazy_thumbnail]
    # ,
    #                   styles: THUMBNAIL_STYLES,
    #                   processors: [:lazy_thumbnail, :blurhash_transcoder, :color_extractor],
    #                   convert_options: GLOBAL_CONVERT_OPTIONS

    validates_attachment_content_type :image, content_type: IMAGE_MIME_TYPES
    validates_attachment_size :image, less_than: IMAGE_LIMIT

    def boost_bot_status

      return unless ENV['BOOST_COMMUNITY_BOT_ENABLED'] == 'true' && ENV['LOCAL_DOMAIN'] == "newsmast.social"

      community_bot_account = get_community_bot_account(self.community_id)
      
      return if community_bot_account.nil? && self.status.banned? && is_blocked_by_admins?(self.community_id, self.status.account_id)
      
      Mammoth::BoostCommunityBotWorker.perform_async(self.status_id, community_bot_account)
    end

    private  

    def get_community_bot_account(community_id)
      Mammoth::Community.where(id: community_id).last&.bot_account
    end

    def is_blocked_by_admins?(community_id, account_id)
      target_account_ids = (
                            Block
                            .where(account_id: Mammoth::Account
                            .joins(users: :community_admins)
                            .where(community_admins: { community_id: community_id}, users: { role_id: 4 })
                            .pluck(:id))
                            .pluck(:target_account_id) + Mute
                            .where(account_id: Mammoth::Account
                            .joins(users: :community_admins)
                            .where(community_admins: { community_id: community_id}, users: { role_id: 4 })
                            .pluck(:id))
                            .pluck(:target_account_id)
                            ).uniq

      return true if target_account_ids.include?(account_id.to_i)
      false
    end

  end
end