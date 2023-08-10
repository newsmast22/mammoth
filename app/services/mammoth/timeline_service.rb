require 'benchmark'
module Mammoth
  class TimelineService < BaseService
    attr_reader :statuses
  
    def initialize(current_account, max_id, current_user)
      @current_account = current_account
      @max_id = max_id
      @current_user = current_user
      @userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: @current_user.id).last
      create_user_timeline_setting
      @query_service = Mammoth::DbQueries::Service::TimelineServiceQuery.new(@max_id)
    end

    def call
      @caller_name = caller[0][/`.*'/][1..-2]
      prepare_result
    end

    private 

    def get_query
      case @caller_name 
      when "primary"
        @sql_query = @query_service.primary_timeline_query
      when "my_community"
        @sql_query = @query_service.my_community_timeline_query
      when "federated"
        @sql_query = @query_service.federated_timeline_query
      when "newsmast"
        @sql_query = @query_service.newsmast_timeline_query
      end
    end

    def create_user_timeline_setting
      @userTimeLineSetting.check_filter_setting
    end

    def prepare_result
      get_query
      query_time = Benchmark.measure do
        @result = Mammoth::Status.find_by_sql([@sql_query, { ACC_ID: @current_account.id,  MAX_ID: @max_id, USR_ID: @current_user.id }])
      end 
      puts "#{@current_account.username} - (#{@current_account.id}) #{@caller_name} timeline query processing time : #{format('%.4f', query_time.real)} seconds"
      status_ids = @result.map(&:status_id)
      @statuses_relation = Mammoth::Status.where(id: status_ids)
      return @statuses_relation
    end
  end
end