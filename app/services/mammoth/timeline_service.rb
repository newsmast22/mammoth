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

    def self.federated_timeline(current_account, max_id, current_user)
      acc_id = current_account.id
      current_user.check_filter_setting

      sql_query = primary_timeline_query(max_id)

      result = Mammoth::Status.find_by_sql([sql_query, { ACC_ID: acc_id,  MAX_ID: max_id, USR_ID: current_user.id }])
      status_ids = result.map(&:id)
      statuses_relation = Mammoth::Status.where(id: status_ids)
      return statuses_relation
    end

    def self.newsmast_timeline(current_account, max_id, current_user)
      acc_id = current_account.id
      current_user.check_filter_setting

      sql_query = primary_timeline_query(max_id)

      result = Mammoth::Status.find_by_sql([sql_query, { ACC_ID: acc_id,  MAX_ID: max_id, USR_ID: current_user.id }])
      status_ids = result.map(&:id)
      statuses_relation = Mammoth::Status.where(id: status_ids)
      return statuses_relation
    end

    def self.format_json
      unless @statuses.empty?
        before_limit_statuses = @statuses
        @statuses = @statuses.order(created_at: :desc).limit(5)
        render json: @statuses, root: 'data', 
                                each_serializer: Mammoth::StatusSerializer, current_user: current_user, adapter: :json, 
                                meta: {
                                  pagination:
                                  { 
                                    total_objects: before_limit_statuses.size,
                                    has_more_objects: 5 <= before_limit_statuses.size ? true : false
                                  } 
                                }
      else
        render json: {
          data: [],
          meta: {
            pagination:
            { 
              total_objects: 0,
              has_more_objects: false
            } 
          }
        }
      end
    end
  end
end