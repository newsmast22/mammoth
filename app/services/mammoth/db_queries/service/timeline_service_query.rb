module Mammoth
  module DbQueries
    module Service
      class TimelineServiceQuery 

        def initialize(max_id)
          @max_id = max_id
          @condition = condition_query
          @authorize_query = Mammoth::DbQueries::Common::StatusAuthorizeQuery.new
          @filter_block_delete_mute = @authorize_query.select_acc_by_block_mute_delete
          @filter_amplifier = @authorize_query.select_acc_by_user_filter
        end

        def my_community_timeline_query
          sql_query = "SELECT statuses.id
                      FROM statuses
                      JOIN mammoth_communities_statuses as commu_status ON statuses.id = commu_status.status_id
                      JOIN mammoth_communities as commu ON commu_status.community_id = commu.id
                      JOIN mammoth_communities_users as commu_usr ON commu_usr.community_id = commu.id
                      WHERE #{@condition}
                      AND #{select_status_without_rss}
                      AND commu.slug != 'breaking_news' 
                      AND commu_usr.user_id = :USR_ID
                      AND statuses.deleted_at IS NULL 
                      AND statuses.account_id NOT IN (#{@filter_block_delete_mute})
                      AND statuses.account_id IN (#{@filter_amplifier})
                      ORDER BY statuses.id DESC;"
          return sql_query
        end

        def primary_timeline_query
          sql_query = "SELECT statuses.id
                      FROM statuses
                      JOIN mammoth_communities_statuses ON statuses.id = mammoth_communities_statuses.status_id
                      JOIN mammoth_communities ON mammoth_communities_statuses.community_id = mammoth_communities.id
                      WHERE #{@condition}
                      AND mammoth_communities.slug != 'breaking_news' 
                      AND #{select_status_without_rss}
                      AND statuses.deleted_at IS NULL 
                      AND statuses.account_id NOT IN (#{@filter_block_delete_mute})
                      ORDER BY statuses.id DESC 
                      ;"

          puts sql_query
          return sql_query
        end

        def newsmast_timeline_query
          sql_query = "SELECT statuses.id
                        FROM statuses
                        WHERE #{@condition}
                        AND statuses.local = true 
                        AND statuses.deleted_at IS NULL 
                        AND statuses.account_id NOT IN (#{@filter_block_delete_mute})
                        ORDER BY statuses.id DESC 
                        ;"
        end

        def federated_timeline_query
          sql_query = "SELECT statuses.id
                        FROM statuses
                        WHERE #{@condition}
                        AND statuses.local = false
                        AND statuses.deleted_at IS NULL 
                        AND statuses.account_id NOT IN (#{@filter_block_delete_mute})
                        ORDER BY statuses.id DESC 
                        ;"
        end

        def select_status_without_rss
          " statuses.reply = FALSE 
          AND statuses.community_feed_id IS NULL 
          AND statuses.group_id IS NULL "
        end

        def condition_query
          if  @max_id.nil?
            condition = "statuses.id > 0"
          else
            condition = "statuses.id < :MAX_ID"
          end
        end
      end
    end
  end
end


                