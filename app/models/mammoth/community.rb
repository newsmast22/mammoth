module Mammoth
  class Community < ApplicationRecord
    self.table_name = 'mammoth_communities'

    include Attachmentable

    has_and_belongs_to_many :statuses, class_name: "Mammoth::Status"
    has_and_belongs_to_many :users, class_name: "Mammoth::User"
    belongs_to :collection, class_name: "Mammoth::Collection"
    has_many :community_users, class_name: "Mammoth::UserCommunity", dependent: :destroy
    has_many :community_admins, class_name: "Mammoth::CommunityAdmin", dependent: :destroy
    has_many :community_statuses, class_name: "Mammoth::CommunityStatus", dependent: :destroy
    has_many :community_filter_keywords, class_name: "Mammoth::CommunityFilterKeyword", dependent: :destroy
    has_many :community_hashtags, class_name: "Mammoth::CommunityHashtag", dependent: :destroy

    scope :get_my_communities, ->(acc_id){
      joins(mammoth_communities_users: { user: :account }).where(account: {id: acc_id})
    }

    scope :get_public_communities, -> (){
      where(is_recommended: true)
    }

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

    scope :get_community_admins, -> {
      joins(community_admins: :user)
      .where(users: { is_active: true })
      .pluck('users.account_id')
    }

    def is_contain_admin?(account_ids)
      Mammoth::Account.joins(users: :community_admins)
      .where(community_admins: {community_id: self.id})
      .where(id: account_ids).any?
    end

    def get_community_admins
      community_admins.joins(:user)
      .where(community_id: self.id)
      .where(users: { is_active: true })
      .pluck('users.account_id')
    end

    def get_communities_admins_account 
      Mammoth::Account.joins(users: :community_admins)
        .where(community_admins: {community_id: self.id})
        .where(users: { is_active: true })
    end

    def included_by_community_statuses
      statuses.order(id: :desc).limit(400).pluck(:id)
      # redis.zrange("feed:community_statuses:#{id}", 0, -1, with_scores: false)
    end

    def last_statuses_400
      statuses.order(id: :desc).limit(400)
    end

    def last_status_at
      community_statuses.order(created_at: :desc).first&.created_at
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


    def self.find_normalized(slug)
      find_by(slug: slug) || (raise ActiveRecord::RecordNotFound, "Couldn't find a record with slug: #{slug}")
    end
    
    def  self.get_communities_by_acc(acc_id)
      joins(community_users: {user: :account})
        .where(accounts: { domain: nil , id: acc_id })
        .where(user: { is_active: true })
        .where.not(slug: "breaking_news")
    end

    def self.get_community_info_details(role_name, current_user, community_slug)

			@user = Mammoth::User.find(current_user.id)

			all_community_hash = Mammoth::CollectionService.all_collection

			community = Mammoth::Community.new(
				name: ENV['ALL_COLLECTION'].capitalize,
				description: all_community_hash[:description],
				collection_id: nil,
				image: nil,
				header: nil,
				slug: ENV['ALL_COLLECTION'],
				id: all_community_hash[:id]
			)

			community = Mammoth::Community.find_by!(slug: community_slug) unless community_slug == ENV['ALL_COLLECTION']

			#begin::check is community-admin
			is_community_admin = false
			user_community_admin= Mammoth::CommunityAdmin.where(user_id: @user.id, community_id: community.id).last
			if user_community_admin.present?
				is_community_admin = true
			end
			#end::check is community-admin

			user_communities_ids  = @user.user_communities.pluck(:community_id).map(&:to_i)

			community_followed_user_counts = Mammoth::UserCommunity.where(community_id: community.id).size

      result = {
          community_followed_user_counts: community_followed_user_counts,
          community_name: role_name == "rss-account" ? current_user.account.display_name : community.name,
          community_description: community.description,
          collection_name: community.try(:collection).try(:name).nil? ? " " : community.try(:collection).try(:name), 
          community_url: community.try(:image).present? ? community.image.url : all_community_hash[:image_url] ,
          community_header_url: community.try(:header).present? ? community.try(:header).try(:url) : all_community_hash[:collection_detail_image_url],
          community_slug: community.slug,
          is_joined: user_communities_ids.include?(community.id),
          is_admin: is_community_admin,
      }
    end

    def self.get_public_community_detail_profile(community_slug)
      all_community_hash = Mammoth::CollectionService.all_collection

      community = Mammoth::Community.new(
				name: ENV['ALL_COLLECTION'].capitalize,
				description: all_community_hash[:description],
				collection_id: nil,
				image: nil,
				header: nil,
				slug: ENV['ALL_COLLECTION'],
				id: all_community_hash[:id]
			)

      community = Mammoth::Community.find_by!(slug: community_slug) unless community_slug == ENV['ALL_COLLECTION']

      community_followed_user_counts = Mammoth::UserCommunity.where(community_id: community.id).size

      result = {
        community_followed_user_counts: community_followed_user_counts,
        community_name: community.name,
        community_description: community.description,
        collection_name: community.try(:collection).try(:name).nil? ? " " : community.try(:collection).try(:name), 
        community_url: community.try(:image).present? ? community.image.url : all_community_hash[:image_url] ,
        community_header_url: community.try(:header).present? ? community.try(:header).try(:url) : all_community_hash[:collection_detail_image_url],
        community_slug: community.slug,
        is_joined: false,
        is_admin: false,
    }
    end

  end
end