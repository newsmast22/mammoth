module Mammoth
  module DbQueries
    module Service
      module TimelineServiceQuery 

        def self.primary_timeline_query(max_id)
          sql_query = "SELECT statuses.id
                      FROM statuses
                      JOIN mammoth_communities_statuses ON statuses.id = mammoth_communities_statuses.status_id
                      JOIN mammoth_communities ON mammoth_communities_statuses.community_id = mammoth_communities.id
                      WHERE #{condition(max_id)}
                      AND mammoth_communities.slug != 'breaking_news' 
                      AND #{select_status_without_rss}
                      AND statuses.account_id NOT IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_block_mute_delete})
                      AND statuses.account_id IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_user_filter})
                      ORDER BY statuses.created_at DESC;"
        end

        def self.newsmast_timeline_query(max_id)
          sql_query = "SELECT statuses.id
                        FROM statuses
                        WHERE #{condition(max_id)}
                        AND statuses.local = true
                        AND statuses.account_id NOT IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_block_mute_delete})
                        AND statuses.account_id IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_user_filter})
                        ORDER BY statuses.created_at DESC;"
        end

        def self.federated_timeline_query(max_id)
          sql_query = "SELECT statuses.id
                        FROM statuses
                        WHERE #{condition(max_id)}
                        AND statuses.local = false
                        AND statuses.account_id NOT IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_block_mute_delete})
                        AND statuses.account_id IN (#{Mammoth::DbQueries::Common::StatusAuthorizeQuery.select_acc_by_user_filter})
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


                