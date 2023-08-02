module Mammoth
  class TimelineService < BaseService
    def self.primary_timeline(current_account, max_id, current_user)
      acc_id = current_account.id
      
      userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id).last
      userTimeLineSetting.check_filter_setting
      sql_query = Mammoth::DbQueries::Service::TimelineServiceQuery.primary_timeline_query(max_id)

      result = Mammoth::Status.find_by_sql([sql_query, { ACC_ID: acc_id,  MAX_ID: max_id, USR_ID: current_user.id }])
      status_ids = result.map(&:id)
      statuses_relation = Mammoth::Status.where(id: status_ids)
      
      return statuses_relation
    end

    def self.my_community_timeline(current_account, max_id, current_user)
      acc_id = current_account.id
      
      userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id).last
      userTimeLineSetting.check_filter_setting
      sql_query = Mammoth::DbQueries::Service::TimelineServiceQuery.my_community_timeline_query(max_id)

      result = Mammoth::Status.find_by_sql([sql_query, { ACC_ID: acc_id,  MAX_ID: max_id, USR_ID: current_user.id }])
      status_ids = result.map(&:id)
      statuses_relation = Mammoth::Status.where(id: status_ids)
      
      return statuses_relation
    end


    def self.federated_timeline(current_account, max_id, current_user)
      acc_id = current_account.id

      userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id).last
      userTimeLineSetting.check_filter_setting

      sql_query = Mammoth::DbQueries::Service::TimelineServiceQuery.federated_timeline_query(max_id)

      result = Mammoth::Status.find_by_sql([sql_query, { ACC_ID: acc_id,  MAX_ID: max_id, USR_ID: current_user.id }])
      status_ids = result.map(&:id)
      statuses_relation = Mammoth::Status.where(id: status_ids)
      return statuses_relation
    end

    def self.newsmast_timeline(current_account, max_id, current_user)
      acc_id = current_account.id

      userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id).last
      userTimeLineSetting.check_filter_setting

      sql_query = Mammoth::DbQueries::Service::TimelineServiceQuery.newsmast_timeline_query(max_id)

      result = Mammoth::Status.find_by_sql([sql_query, { ACC_ID: acc_id,  MAX_ID: max_id, USR_ID: current_user.id }])
      status_ids = result.map(&:id)
      statuses_relation = Mammoth::Status.where(id: status_ids)
      return statuses_relation
    end
  end
end