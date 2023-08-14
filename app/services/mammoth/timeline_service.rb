require 'benchmark'
module Mammoth
  class TimelineService < BaseService
    attr_reader :statuses
  
    def initialize(current_account, max_id, current_user)
      ActiveRecord::Base.connected_to(role: :reading) do 
        puts "********** DB Host Swithcing in Timeline 1************"
        puts ActiveRecord::Base.connection_db_config.database
        #ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['primary_replica'])
        #puts ActiveRecord::Base.connection_db_config.database
        @current_account = current_account
        @max_id = max_id
        @current_user = current_user
        @userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: @current_user.id).last
        create_user_timeline_setting
        @query_service = Mammoth::DbQueries::Service::TimelineServiceNew.new(@max_id,@current_user,@current_account)
      end
    end

    def call
      @caller_name = caller[0][/`.*'/][1..-2]
      prepare_result
    end

    private 

    def get_query
      case @caller_name 
      when "primary"
        @statuses = @query_service.primary_timeline
      when "my_community"
        @statuses = @query_service.my_community_timeline
      when "federated"
        @statuses = @query_service.federated_timeline
      when "newsmast"
        @statuses = @query_service.newsmast_timeline
      end
    end

    def create_user_timeline_setting
      @userTimeLineSetting.check_filter_setting
    end

    def prepare_result
      query_time = Benchmark.measure do
        get_query
      end 
      puts "#{@current_account.username} - (#{@current_account.id}) #{@caller_name} 
              timeline process time : #{format('%.4f', query_time.real)} seconds"

      if !(@statuses.nil? || @statuses.count == 0)
        @statuses = Mammoth::Status.where(id: @statuses.pluck(:id))
      end
      return @statuses
    end
  end
end