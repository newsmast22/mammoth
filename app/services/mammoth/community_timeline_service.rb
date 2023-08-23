require 'benchmark'
module Mammoth
  class CommunityTimelineService < BaseService
    def initialize(current_account, max_id, current_user, current_community, page_no)
      @current_account = current_account
      @max_id = max_id
      @current_user = current_user
      @page_no = page_no
      @userCommunitySetting = Mammoth::UserCommunitySetting.where(user_id: @current_user.id).last
      create_user_community_setting  
      @query_service = Mammoth::DbQueries::Service::UserCommunityServiceQuery.new(@max_id, @current_user, @current_account, current_community, @page_no)
    end

    def call
      @caller_name = caller[0][/`.*'/][1..-2]
      prepare_result
    end

    private 

    def get_query
      ActiveRecord::Base.connected_to(role: :reading) do
        case @caller_name
        when "all"
          @statuses = @query_service.all_timeline
        when "recommended"
          @statuses = @query_service.recommended_timeline
        end
      end
    end

    def prepare_result
      query_time = Benchmark.measure do
        get_query
      end 
      puts "#{@current_account.username} - (#{@current_account.id}) user_communtiy's #{@caller_name} timeline process time : #{format('%.4f', query_time.real)} seconds"
      return @statuses
    end
    
    def create_user_community_setting
      if @userCommunitySetting.nil?
        Mammoth::UserCommunitySetting.create_userTimelineSetting(@current_user)
      end
    end
  end
end