module Mammoth
  class User < User
    self.table_name = 'users'
    
    has_and_belongs_to_many :communities, class_name: "Mammoth::Community"
    has_many :user_communities , class_name: "Mammoth::UserCommunity"
    has_many :community_admins, class_name: "Mammoth::CommunityAdmin"
    has_many :user_timeline_settings, class_name: "Mammoth::UserTimelineSetting"
    belongs_to :wait_list, inverse_of: :user, optional: true


    scope :filter_with_words, ->(words) { joins(:account).where("LOWER(users.email) like '%#{words}%' OR LOWER(users.phone) like '%#{words}%' OR LOWER(accounts.username) like '%#{words}%' OR LOWER(accounts.display_name) like '%#{words}%'") }
    scope :filter_blocked_accounts,->(account_ids) {where.not(account_id: account_ids)}

    def is_filter_turn_on?
      @user_timeline_setting = user_timeline_settings.last
      if @user_timeline_setting
        @selected_filters =  @user_timeline_setting.selected_filters
        return @user_timeline_setting.selected_filters["is_filter_turn_on"] == true 
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

      @selected_filter_usr = OpenStruct.new(selected_countries: @selected_countries, 
                              selected_contributor_role: @selected_contributor_role, 
                              selected_voices: @selected_voices, 
                              selected_media: @selected_media)

      return @selected_filter_usr
    end
  end
end