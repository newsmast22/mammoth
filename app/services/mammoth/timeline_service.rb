require 'benchmark'
module Mammoth
  class TimelineService < BaseService
  
    def initialize(current_account, max_id, current_user)
      @current_account = current_account
      @max_id = max_id
      @current_user = current_user
      @userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: @current_user.id).last
      create_user_timeline_setting
    end

    def primary_timeline
      @sql_query = Mammoth::DbQueries::Service::TimelineServiceQuery.primary_timeline_query(@max_id)
      prepare_result
    end

    def my_community_timeline
      @sql_query = Mammoth::DbQueries::Service::TimelineServiceQuery.my_community_timeline_query(@max_id)
      prepare_result
    end


    def federated_timeline
      @sql_query = Mammoth::DbQueries::Service::TimelineServiceQuery.federated_timeline_query(@max_id)
      prepare_result
    end

    def newsmast_timeline
      @sql_query = Mammoth::DbQueries::Service::TimelineServiceQuery.newsmast_timeline_query(@max_id)
      prepare_result
    end

    private 

    def create_user_timeline_setting
      @userTimeLineSetting.check_filter_setting
    end

    def prepare_result
      query_time = Benchmark.measure do
        @result = Mammoth::Status.find_by_sql([@sql_query, { ACC_ID: @current_account.id,  MAX_ID: @max_id, USR_ID: @current_user.id }])
      end
      status_ids = @result.map(&:id)
      statuses_relation = Mammoth::Status.where(id: status_ids)
      puts "Query processing time : #{query_time.real} seconds"
      return statuses_relation
    end
  end
end