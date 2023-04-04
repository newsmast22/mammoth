# frozen_string_literal: true
module Mammoth
  class FollowingFeed
    # @param [Account] account
    # @param [Hash] options
    # @option [Boolean] :with_replies
    # @option [Boolean] :with_reblogs
    # @option [Boolean] :local
    # @option [Boolean] :remote
    # @option [Boolean] :only_media
    def initialize(account, options = {})
      @account = account
      @options = options
    end

    # @param [Integer] limit
    # @param [Integer] max_id
    # @param [Integer] since_id
    # @param [Integer] min_id
    # @return [Array<Status>]
    def get(limit, max_id = nil, since_id = nil, min_id = nil,filtered_following_statuses,user_id)
      scope = fetch_following_filter_timeline(filtered_following_statuses,user_id)
      # scope.merge!(without_replies_scope) unless with_replies?
      # scope.merge!(without_reblogs_scope) unless with_reblogs?
      # scope.merge!(local_only_scope) if local_only?
      # scope.merge!(remote_only_scope) if remote_only?
      # scope.merge!(account_filters_scope) if account?
      # scope.merge!(media_only_scope) if media_only?
      # scope.merge!(language_scope) if account&.chosen_languages.present?

      scope.cache_ids.to_a_paginated_by_id(limit, max_id: max_id, since_id: since_id, min_id: min_id)
    end

    private

    attr_reader :account, :options

    def with_reblogs?
      options[:with_reblogs]
    end

    def with_replies?
      options[:with_replies]
    end

    def local_only?
      options[:local]
    end

    def remote_only?
      options[:remote]
    end

    def account?
      account.present?
    end

    def media_only?
      options[:only_media]
    end

    def public_scope
      Status.with_public_visibility.joins(:account).merge(Account.without_suspended.without_silenced)
    end

    def local_only_scope
      Status.local
    end

    def remote_only_scope
      Status.remote
    end

    def without_replies_scope
      Status.without_replies
    end

    def without_reblogs_scope
      Status.without_reblogs
    end

    def media_only_scope
      Status.joins(:media_attachments).group(:id)
    end

    def language_scope
      Status.where(language: account.chosen_languages)
    end

    def account_filters_scope
      Status.not_excluded_by_account(account).tap do |scope|
        scope.merge!(Status.not_domain_blocked_by_account(account)) unless local_only?
      end
    end

    def fetch_following_filter_timeline(filtered_followed_statuses, user_id)
      @statuses = filtered_followed_statuses

      @user_timeline_setting = Mammoth::UserTimelineSetting.find_by(user_id: user_id)
      
      return @statuses if @user_timeline_setting.nil? || @user_timeline_setting.selected_filters["is_filter_turn_on"] == false 

      #begin::country filter
      is_country_filter = false
      
      # filter: country_filter_on && selected_country exists
      if @user_timeline_setting.selected_filters["location_filter"]["selected_countries"].any? && @user_timeline_setting.selected_filters["location_filter"]["is_location_filter_turn_on"] == true
        accounts = Mammoth::Account.filter_timeline_with_countries(@user_timeline_setting.selected_filters["location_filter"]["selected_countries"]) 
        is_country_filter = true
      end

      if is_country_filter == true && accounts.blank? == true
        return @statuses = []
      end
      #end::country filter
      
      #begin:: source filter: contributor_role, voice, media
      accounts = Mammoth::Account.all if accounts.blank?

      accounts = accounts.filter_timeline_with_contributor_role(@user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_contributor_role"].present?

      accounts = accounts.filter_timeline_with_voice(@user_timeline_setting.selected_filters["source_filter"]["selected_voices"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_voices"].present?

      accounts = accounts.filter_timeline_with_media(@user_timeline_setting.selected_filters["source_filter"]["selected_media"]) if @user_timeline_setting.selected_filters["source_filter"]["selected_media"].present?
      #end:: source filter: contributor_role, voice, media

      @statuses = @statuses.filter_timeline_with_accounts(accounts.pluck(:id).map(&:to_i))

      #begin::community filter
      if @user_timeline_setting.selected_filters["communities_filter"]["selected_communities"].present?
        status_tag_ids = Mammoth::CommunityStatus.group(:community_id,:status_id).where(community_id: @user_timeline_setting.selected_filters["communities_filter"]["selected_communities"]).pluck(:status_id).map(&:to_i)
        @statuses = @statuses.merge(Mammoth::Status.filter_without_community_status_ids(status_tag_ids))
      end
      #end::community filter
    end

  end
end