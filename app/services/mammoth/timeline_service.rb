require 'benchmark'
module Mammoth
  class TimelineService < BaseService
    attr_reader :statuses
  
    def initialize(current_account, max_id, current_user, page_no)
      @current_account = current_account
      @max_id = max_id
      @current_user = current_user
      @page_no = page_no
      @userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: @current_user.id).last
      create_user_timeline_setting
      @query_service = Mammoth::DbQueries::Service::TimelineServiceNew.new(@max_id,@current_user,@current_account, @page_no)
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
        when "my_community"
          @statuses = @query_service.my_community_timeline
        when "federated"
          @statuses = @query_service.federated_timeline
        when "newsmast"
          @statuses = @query_service.newsmast_timeline
        when "following"
          @statuses = @query_service.following_timeline
        when "index"
          @statuses = @query_service.following_timeline
        end
      end
    end
    
    

    def create_user_timeline_setting
      if @userTimeLineSetting.nil? 
        Mammoth::UserTimelineSetting.create_userTimelineSetting(@current_user)
      end
    end

    def prepare_result
      query_time = Benchmark.measure do
        get_query
      end 
      puts "#{@current_account.username} - (#{@current_account.id}) #{@caller_name} timeline process time : #{format('%.4f', query_time.real)} seconds"
      return @statuses
    end
  end
end