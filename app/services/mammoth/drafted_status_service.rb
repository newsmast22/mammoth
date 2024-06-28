# frozen_string_literal: true
module Mammoth
  class DraftedStatusService < BaseService
    include Redisable
    include LanguagesHelper

    MIN_SCHEDULE_OFFSET = 5.minutes.freeze

    class UnexpectedMentionsError < StandardError
      attr_reader :accounts

      def initialize(message, accounts)
        super(message)
        @accounts = accounts
      end
    end

    # Post a text status update, fetch and notify remote users mentioned
    # @param [Account] account Account from which to post
    # @param [Hash] options
    # @option [String] :text Message
    # @option [Status] :thread Optional status to reply to
    # @option [Boolean] :sensitive
    # @option [String] :visibility
    # @option [String] :spoiler_text
    # @option [String] :language
    # @option [String] :scheduled_at
    # @option [Hash] :poll Optional poll to attach
    # @option [Enumerable] :media_ids Optional array of media IDs to attach
    # @option [Doorkeeper::Application] :application
    # @option [String] :idempotency Optional idempotency key
    # @option [Boolean] :with_rate_limit
    # @option [Enumerable] :allowed_mentions Optional array of expected mentioned account IDs, raises `UnexpectedMentionsError` if unexpected accounts end up in mentions
    # @return [Status]
    def call(account, options = {})
      @account     = account
      @options     = options
      @text        = @options[:text] || ''
      @in_reply_to = @options[:thread]

      return idempotency_duplicate if idempotency_given? && idempotency_duplicate?

      validate_media!
      preprocess_attributes!

      if scheduled?
        schedule_status!
      elsif drafted?
        draft_status!
      else
        process_status!
      end

      redis.setex(idempotency_key, 3_600, @status.id) if idempotency_given?

      if @status
        # To check text contains filtered keywords
        # If keywords contains, save record in community filter statuses
        # Assume user selected mulitple community
        Mammoth::StatusBunWorker.perform_async(@status.id, options = { actions: 'create' })
      end

      unless scheduled? || drafted?
        postprocess_status!
        bump_potential_friendship!
      end

      @status
    end

    private

    def preprocess_attributes!
      @sensitive    = (@options[:sensitive].nil? ? @account.user&.setting_default_sensitive : @options[:sensitive]) || @options[:spoiler_text].present?
      @text         = @options.delete(:spoiler_text) if @text.blank? && @options[:spoiler_text].present?
      @visibility   = @options[:visibility] || @account.user&.setting_default_privacy
      @visibility   = :unlisted if @visibility&.to_sym == :public && @account.silenced?
      @scheduled_at = @options[:scheduled_at]&.to_datetime
      @scheduled_at = nil if scheduled_in_the_past?
      @drafted      = @options[:drafted] 
    rescue ArgumentError
      raise ActiveRecord::RecordInvalid
    end

    def update_community_ids!
      @community_ids = validate_communites!

      if @community_ids.size.positive?
        @community_ids = Mammoth::Community.where(slug: @community_ids).pluck(:id).to_a.uniq
        if @community_ids.any?
          @community_ids.each do |community_id|
            Mammoth::CommunityStatus.find_or_create_by(status_id: @status.id, community_id: community_id)

            # Newsmast.community bot's account boosting or reblog with community
            Mammoth::BoostCommunityBotWorker.perform_async(community_id, @status.id) if is_community_bot_shareable?
          end
        end
      else

        # Newsmast.community bot's account boosting or reblog without community
        Mammoth::BoostCommunityBotWorker.perform_async(nil, @status.id) if @options.key?(:community_ids) && is_community_bot_shareable?
      end
      
      @status.communities.reload
    end

    def is_community_bot_shareable?
      return false unless ENV['BOOST_COMMUNITY_BOT_ENABLED'] == 'true' && ENV['LOCAL_DOMAIN'] == "newsmast.social"
      true
    end

    def process_status!
      @status = @account.statuses.new(status_attributes)
      process_mentions_service.call(@status, save_records: false)
      safeguard_mentions!(@status)

      # The following transaction block is needed to wrap the UPDATEs to
      # the media attachments when the status is created
      ApplicationRecord.transaction do
        @status.save!
      end
      update_community_ids! if @options.key?(:community_ids)
    end

    def safeguard_mentions!(status)
      return if @options[:allowed_mentions].nil?

      expected_account_ids = @options[:allowed_mentions].map(&:to_i)

      unexpected_accounts = status.mentions.map(&:account).to_a.reject { |mentioned_account| expected_account_ids.include?(mentioned_account.id) }
      return if unexpected_accounts.empty?

      raise UnexpectedMentionsError.new('Post would be sent to unexpected accounts', unexpected_accounts)
    end

    def schedule_status!
      status_for_validation = @account.statuses.build(status_attributes)

      if status_for_validation.valid?
        # Marking the status as destroyed is necessary to prevent the status from being
        # persisted when the associated media attachments get updated when creating the
        # scheduled status.
        status_for_validation.destroy

        # The following transaction block is needed to wrap the UPDATEs to
        # the media attachments when the scheduled status is created

        ApplicationRecord.transaction do
          @status = @account.scheduled_statuses.create!(scheduled_status_attributes)
        end
      else
        raise ActiveRecord::RecordInvalid
      end
    end

    def draft_status!
      status_for_validation = @account.statuses.build(status_attributes)

      if status_for_validation.valid?
        # Marking the status as destroyed is necessary to prevent the status from being
        # persisted when the associated media attachments get updated when creating the
        # scheduled status.
        status_for_validation.destroy

        # The following transaction block is needed to wrap the UPDATEs to
        # the media attachments when the drafted status is created

        ApplicationRecord.transaction do
          @status = @account.mammoth_drafted_statuses.create!(drafted_status_attributes)
        end
      else
        raise ActiveRecord::RecordInvalid
      end
    end

    def postprocess_status!
      process_hashtags_service.call(@status) unless @options[:is_rss_content]
      process_mentions_service.call(@status)
      Trends.tags.register(@status)
      LinkCrawlWorker.perform_async(@status.id)
      DistributionWorker.perform_async(@status.id) unless @status.banned?
      ActivityPub::DistributionWorker.perform_async(@status.id) unless @status.banned?
      PollExpirationNotifyWorker.perform_at(@status.poll.expires_at, @status.poll.id) if @status.poll
      Mammoth::BoostBotWorker.perform_async(@status.id) if is_local_bot_shareable?
    end

    def is_local_bot_shareable?
      return true if ENV['BOOST_BOT_ENABLED'] == 'true' && @status.local? && !@status.reply && !@status.is_rss_content
      false
    end

    def validate_media!
      if @options[:media_ids].blank? || !@options[:media_ids].is_a?(Enumerable)
        @media = []
        return
      end

      raise Mastodon::ValidationError, I18n.t('media_attachments.validations.too_many') if @options[:media_ids].size > 4 || @options[:poll].present?

      @media = @account.media_attachments.where(status_id: nil).where(id: @options[:media_ids].take(4).map(&:to_i))

      raise Mastodon::ValidationError, I18n.t('media_attachments.validations.images_and_video') if @media.size > 1 && @media.find(&:audio_or_video?)
      raise Mastodon::ValidationError, I18n.t('media_attachments.validations.not_ready') if @media.any?(&:not_processed?)
    end

    def process_mentions_service
      ProcessMentionsService.new
    end

    def process_hashtags_service
      ProcessHashtagsService.new
    end

    def scheduled?
      @scheduled_at.present?
    end

    def drafted?
      @drafted.present?
    end

    def idempotency_key
      "idempotency:status:#{@account.id}:#{@options[:idempotency]}"
    end

    def idempotency_given?
      @options[:idempotency].present?
    end

    def idempotency_duplicate
      if scheduled?
        @account.schedule_statuses.find(@idempotency_duplicate)
      else
        @account.statuses.find(@idempotency_duplicate)
      end
    end

    def idempotency_duplicate?
      @idempotency_duplicate = redis.get(idempotency_key)
    end

    def scheduled_in_the_past?
      @scheduled_at.present? && @scheduled_at <= Time.now.utc + MIN_SCHEDULE_OFFSET
    end

    def bump_potential_friendship!
      return if !@status.reply? || @account.id == @status.in_reply_to_account_id

      ActivityTracker.increment('activity:interactions')
      return if @account.following?(@status.in_reply_to_account_id)

      PotentialFriendshipTracker.record(@account.id, @status.in_reply_to_account_id, :reply)
    end

    def status_attributes
      {
        text: @text,
        media_attachments: @media || [],
        ordered_media_attachment_ids: (@options[:media_ids] || []).map(&:to_i) & @media.map(&:id),
        thread: @in_reply_to,
        poll_attributes: poll_attributes,
        sensitive: @sensitive,
        spoiler_text: @options[:spoiler_text] || '',
        visibility: @visibility,
        language: valid_locale_cascade(@options[:language], @account.user&.preferred_posting_language, I18n.default_locale),
        application: @options[:application],
        rate_limit: @options[:with_rate_limit],
        is_only_for_followers: @options.key?(:is_only_for_followers) ? @options[:is_only_for_followers] : true,
        is_meta_preview: @options.key?(:is_meta_preview) ? @options[:is_meta_preview] : false,
        text_count: @options.key?(:text_count) ? @options[:text_count] : 0,
        community_feed_id: @options[:community_feed_id],
        rss_link: @options[:rss_link],
        is_rss_content: @options[:is_rss_content],
      }.compact
    end

    def scheduled_status_attributes
      {
        scheduled_at: @scheduled_at,
        media_attachments: @media || [],
        params: scheduled_options,
      }
    end

    def drafted_status_attributes
      {
        media_attachments: @media || [],
        params: scheduled_options,
      }
    end

    def poll_attributes
      return if @options[:poll].blank?

      @options[:poll].merge(account: @account, voters_count: 0)
    end

    def scheduled_options
      @options.tap do |options_hash|
        options_hash[:in_reply_to_id]  = options_hash.delete(:thread)&.id
        options_hash[:application_id]  = options_hash.delete(:application)&.id
        options_hash[:scheduled_at]    = nil
        options_hash[:idempotency]     = nil
        options_hash[:with_rate_limit] = false
      end
    end

    def validate_communites!
      return [] if @options[:community_ids].blank?

      @options[:community_ids]
    end
  end
end
