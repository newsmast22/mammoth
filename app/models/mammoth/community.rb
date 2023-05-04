module Mammoth
  class Community < ApplicationRecord
    self.table_name = 'mammoth_communities'

    include Attachmentable

    has_and_belongs_to_many :statuses, class_name: "Mammoth::Status"
    has_and_belongs_to_many :users, class_name: "Mammoth::User"
    belongs_to :collection, class_name: "Mammoth::Collection"


  	IMAGE_LIMIT = 100.megabytes

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

  	has_attached_file :image,
                      styles: THUMBNAIL_STYLES
                      # ,
                      # processors: [:lazy_thumbnail, :blurhash_transcoder, :color_extractor],
                      # convert_options: GLOBAL_CONVERT_OPTIONS

    validates_attachment_content_type :image, content_type: IMAGE_MIME_TYPES
    validates_attachment_size :image, less_than: IMAGE_LIMIT
    
    def image_name=(name)
      self.image_file_name = name if name.present?
    end

    def image_data=(data)
      self.image = {data: data} if data.present?
    end

    has_attached_file :header,
    styles: THUMBNAIL_STYLES
    # ,
    # processors: [:lazy_thumbnail, :blurhash_transcoder, :color_extractor],
    # convert_options: GLOBAL_CONVERT_OPTIONS

    validates_attachment_content_type :header, content_type: IMAGE_MIME_TYPES
    validates_attachment_size :header, less_than: IMAGE_LIMIT

    def header_name=(name)
      self.header_file_name = name if name.present?
    end

    def header_data=(data)
      self.header = {data: data} if data.present?
    end

  end
end