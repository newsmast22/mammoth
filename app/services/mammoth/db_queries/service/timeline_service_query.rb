module Mammoth
  module DbQueries
    module Service
      module TimelineServiceQuery 

        def self.my_community_timeline_query(max_id)
          sql_query = "SELECT statuses.id
                      FROM statuses
                      JOIN mammoth_communities_statuses as commu_status ON statuses.id = commu_status.status_id
                      JOIN mammoth_communities as commu ON commu_status.community_id = commu.id
                      JOIN mammoth_communities_users as commu_usr ON commu_usr.community_id = commu.id
                      LEFT JOIN mammoth_community_filter_statuses as commu_filter_status ON commu_filter_status.status_id = statuses.id
                      WHERE #{condition(max_id)}
                      AND #{select_status_without_rss}
                      AND commu.slug != 'breaking_news' 
                      AND commu_usr.user_id = :USR_ID
                      AND commu_filter_status.id IS NULL
                      AND statuses.deleted_at IS NULL 
                      AND statuses.account_id NOT IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_block_mute_delete})
                      AND statuses.account_id IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_user_filter})
                      ORDER BY statuses.created_at DESC;"
          puts sql_query
          return sql_query
        end

        def self.primary_timeline_query(max_id)
          sql_query = "SELECT statuses.id
                      FROM statuses
                      JOIN mammoth_communities_statuses ON statuses.id = mammoth_communities_statuses.status_id
                      JOIN mammoth_communities ON mammoth_communities_statuses.community_id = mammoth_communities.id
                      LEFT JOIN mammoth_community_filter_statuses as commu_filter_status ON commu_filter_status.status_id = statuses.id
                      WHERE #{condition(max_id)}
                      AND mammoth_communities.slug != 'breaking_news' 
                      AND #{select_status_without_rss}
                      AND commu_filter_status.id IS NULL
                      AND statuses.deleted_at IS NULL 
                      AND statuses.account_id NOT IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_block_mute_delete})
                      AND statuses.account_id IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_user_filter})
                      ORDER BY statuses.created_at DESC;"
        end

        def self.newsmast_timeline_query(max_id)
          sql_query = "SELECT statuses.id
                        FROM statuses
                        LEFT JOIN mammoth_community_filter_statuses as commu_filter_status ON commu_filter_status.status_id = statuses.id
                        WHERE #{condition(max_id)}
                        AND statuses.local = true 
                        AND commu_filter_status.id IS NULL
                        AND statuses.deleted_at IS NULL 
                        AND statuses.account_id NOT IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_block_mute_delete})
                        AND statuses.account_id IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_user_filter})
                        ORDER BY statuses.created_at DESC;"
        end

        def self.federated_timeline_query(max_id)
          sql_query = "SELECT statuses.id
                        FROM statuses
                        LEFT JOIN mammoth_community_filter_statuses as commu_filter_status ON commu_filter_status.status_id = statuses.id
                        WHERE #{condition(max_id)}
                        AND statuses.local = false
                        AND commu_filter_status.id IS NULL
                        AND statuses.deleted_at IS NULL 
                        AND statuses.account_id NOT IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_block_mute_delete})
                        ORDER BY statuses.created_at DESC;"
        end

        def self.select_status_without_rss
          " statuses.reply = FALSE 
          AND statuses.community_feed_id IS NULL 
          AND statuses.group_id IS NULL "
        end

        def self.condition(max_id) 
          if  max_id.nil?
            condition = "statuses.id > 0"
          else
            condition = "statuses.id < :MAX_ID"
          end
        end
      end
    end
  end
end


                