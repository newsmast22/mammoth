module Mammoth
  class User < User
    self.table_name = 'users'
    
    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    has_many :user_communities , class_name: "Mammoth::UserCommunity"
    has_many :community_admins, class_name: "Mammoth::CommunityAdmin"
    has_many :user_timeline_settings, class_name: "Mammoth::UserTimelineSetting"
    has_many :user_community_settings, class_name: "Mammoth::UserCommunitySetting"
    belongs_to :wait_list, inverse_of: :user, optional: true


    scope :filter_with_words, ->(words) { joins(:account).where("LOWER(users.email) like '%#{words}%' OR LOWER(users.phone) like '%#{words}%' OR LOWER(accounts.username) like '%#{words}%' OR LOWER(accounts.display_name) like '%#{words}%'") }
    scope :filter_blocked_accounts,->(account_ids) {where.not(account_id: account_ids)}

    def primary_user_community
      primary_user_community = user_communities.where(user_id: self.id, is_primary: true).last
      return primary_user_community
    end

    def is_community_admin(commu_id)
      community_admins.where(user_id: self.id, community_id: commu_id).last.present?
    end

    def is_community_filter_turn_on?
      @user_community_setting = user_community_settings.last
      if @user_community_setting
        @selected_filters = @user_community_setting.selected_filters
        return @selected_filters["is_filter_turn_on"] == true 
      else
        return false
      end
    end

    def is_filter_turn_on?
      @user_timeline_setting = user_timeline_settings.last
      if @user_timeline_setting
        @selected_filters =  @user_timeline_setting.selected_filters
        return @selected_filters["is_filter_turn_on"] == true 
      else 
        return false
      end
    end

    def is_location_filter_turn_on?
      @selected_filters["location_filter"]["is_location_filter_turn_on"] == true
    end

    def is_selected_countries_present?
      @selected_filters["location_filter"]["selected_countries"].present?
    end

    def is_selected_contributor_role_persent?
      @selected_filters["source_filter"]["selected_contributor_role"].present?
    end

    def is_selected_voices_present?
      @selected_filters["source_filter"]["selected_voices"].present?
    end

    def is_selected_media_present?
      @selected_filters["source_filter"]["selected_media"].present?
    end

    def selected_filters_for_user
      if is_filter_turn_on?
        perpare_filter_objs
      end
      
      @selected_filter_usr = OpenStruct.new(selected_countries: @selected_countries, 
                              selected_contributor_role: @selected_contributor_role, 
                              selected_voices: @selected_voices, 
                              selected_media: @selected_media)

      return @selected_filter_usr
    end

    def selected_filters_for_user
      if is_filter_turn_on?
        perpare_filter_objs
      end

      @selected_filter_usr = OpenStruct.new(selected_countries: @selected_countries, 
                              selected_contributor_role: @selected_contributor_role, 
                              selected_voices: @selected_voices, 
                              selected_media: @selected_media)

      return @selected_filter_usr
    end

    def selected_user_community_filter
      if is_community_filter_turn_on?
        perpare_filter_objs
      end

      @selected_filter_usr = OpenStruct.new(selected_countries: @selected_countries, 
                              selected_contributor_role: @selected_contributor_role, 
                              selected_voices: @selected_voices, 
                              selected_media: @selected_media)

      return @selected_filter_usr
    end

    def perpare_filter_objs
      if is_location_filter_turn_on? && is_selected_countries_present?
        @selected_countries = @selected_filters["location_filter"]["selected_countries"]
      end

      if is_selected_contributor_role_persent?
        @selected_contributor_role = @selected_filters["source_filter"]["selected_contributor_role"]
      end

      if is_selected_voices_present?
        @selected_voices = @selected_filters["source_filter"]["selected_voices"]
      end 

      if is_selected_media_present?
        @selected_media = @selected_filters["source_filter"]["selected_media"]
      end
    end

    def self.search_global_users(limit , offset, keywords, current_account)

      # Assign limit = 5 as 6 if limit is nil
      # Limit always plus one 
      # Addition plus one to get has_more_object
      @search_limit =  limit
      @search_offset = offset.nil? ? 0 : offset
      @search_keywords = keywords
      @current_account = current_account

      #begin::search from other instance
      filtered_accounts = []
      unless @search_keywords.nil?
        filtered_accounts = perform_accounts_search! if account_searchable?
        @accounts = Account.where.not(id: @current_account.id).where(id: filtered_accounts.pluck(:id)).order(id: :desc) 
      end

      unless filtered_accounts.any? || !@search_keywords.nil?
        unless @search_offset.nil?
          @accounts = Account.joins("LEFT JOIN users on accounts.id = users.account_id").where("
            users.role_id IS NULL AND accounts.id != #{@current_account.id} AND (accounts.actor_type IS NULL OR accounts.actor_type = 'Person')").order(id: :desc).offset(@search_offset) 
        else
          @accounts = Account.joins("LEFT JOIN users on accounts.id = users.account_id").where("
            users.role_id IS NULL AND accounts.id != #{@current_account.id} AND (accounts.actor_type IS NULL OR accounts.actor_type = 'Person') ").order(id: :desc).limit(@search_limit)
        end
      end
      #end::search from other instance

      @accounts

    end

    private

    def self.account_searchable?
      !(@search_keywords.start_with?('#') || (@search_keywords.include?('@') && @search_keywords.include?(' ')))
    end

    def self.perform_accounts_search!
      AccountSearchService.new.call(
        @search_keywords,
        @current_account,
        limit: @search_limit,
        resolve: true,
        offset: @search_offset
      )
    end

  end
end