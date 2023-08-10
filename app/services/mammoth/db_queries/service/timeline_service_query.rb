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
          sql_query ="WITH 
                        #{selected_filters}, 
                        #{filtered_data},
                        part_one AS (
                          SELECT s.id AS status_id , s.account_id AS account_id
                          FROM statuses as s
                            JOIN mammoth_communities_statuses as commu_status ON s.id = commu_status.status_id
                            JOIN mammoth_communities as commu ON commu_status.community_id = commu.id
                            JOIN mammoth_communities_users as commu_usr ON commu_usr.community_id = commu.id
                          WHERE  #{@condition}
                            AND commu.slug != 'breaking_news' 
                            AND commu_usr.user_id = :USR_ID
                        #{filter_rss}
                            AND s.deleted_at IS NULL), 
                        #{block_mute_inactive},
                        #{bunned_status_filter},
                        #{part_four_filter}"
          return sql_query
        end

        def primary_timeline_query
          sql_query = "WITH 
                    #{selected_filters}, 
                    #{filtered_data},
                    part_one AS (
                      SELECT s.id AS status_id , s.account_id AS account_id
                      FROM statuses as s
                      JOIN mammoth_communities_statuses as commu_status ON s.id = commu_status.status_id
                      JOIN mammoth_communities as commu ON commu_status.community_id = commu.id
                      WHERE  #{@condition}
                        AND commu.slug != 'breaking_news' 
                    #{filter_rss}
                        AND s.deleted_at IS NULL), 
                    #{block_mute_inactive},
                    #{bunned_status_filter}
                    #{fooder_filter}"
          return sql_query
        end

        def newsmast_timeline_query
          sql_query = "WITH 
                    #{selected_filters}, 
                    #{filtered_data},
                    part_one AS (
                      SELECT s.id AS status_id , s.account_id AS account_id
                      FROM statuses as s
                      WHERE  #{@condition}
                        AND s.local = true
                        AND s.deleted_at IS NULL), 
                    #{block_mute_inactive},
                    #{bunned_status_filter}
                    #{fooder_filter}"
          return sql_query
        end

        def federated_timeline_query
          sql_query = "WITH 
                      #{selected_filters}, 
                      #{filtered_data},
                      part_one AS (
                        SELECT s.id AS status_id , s.account_id AS account_id
                        FROM statuses as s
                        WHERE  #{@condition}
                          AND s.local = false
                          AND s.deleted_at IS NULL), 
                      #{block_mute_inactive},
                      #{bunned_status_filter}
                      #{fooder_filter}"
          return sql_query
        end

        def select_status_without_rss
          " statuses.reply = FALSE 
          AND statuses.community_feed_id IS NULL 
          AND statuses.group_id IS NULL "
        end

        def condition_query
          if  @max_id.nil?
            condition = "s.id > 0"
          else
            condition = "s.id < :MAX_ID"
          end
        end

        def part_four_filter
          "filtered_accounts AS (
            SELECT accounts.* 
            FROM accounts JOIN part_three 
            ON accounts.id = part_three.account_id
          ),
          part_four AS (
            SELECT filtered_accounts.id AS id
            FROM filtered_accounts
            WHERE 
              CASE
                WHEN (SELECT COUNT(filtered_data.country_codes) FROM filtered_data 
                      WHERE filtered_data.is_location_filter_turn_on = true ) > 0 THEN
                  country = ANY (
                    SELECT country_codes
                    FROM filtered_data
                    WHERE country_codes IS NOT NULL
                  )
                ELSE
                  TRUE
              END
              INTERSECT
              SELECT filtered_accounts.id AS id
              FROM filtered_accounts
              WHERE 
                CASE
                  WHEN (SELECT COUNT(filtered_data.contributor_role_ids) FROM filtered_data ) > 0 THEN
                    about_me_title_option_ids && ARRAY(
                      SELECT contributor_role_ids
                      FROM filtered_data
                      WHERE contributor_role_ids IS NOT NULL
                    )
                  ELSE
                    TRUE
                END
              INTERSECT
              SELECT filtered_accounts.id AS id
              FROM filtered_accounts
              WHERE 
                CASE
                  WHEN (SELECT COUNT(filtered_data.media_ids) FROM filtered_data ) > 0 THEN
                    about_me_title_option_ids && ARRAY(
                      SELECT media_ids
                      FROM filtered_data
                      WHERE media_ids IS NOT NULL
                    )
                  ELSE
                    TRUE
                END
              INTERSECT
              SELECT filtered_accounts.id AS id
              FROM filtered_accounts
              WHERE 
                CASE
                  WHEN (SELECT COUNT(filtered_data.voice_ids) FROM filtered_data ) > 0 THEN
                    about_me_title_option_ids && ARRAY(
                      SELECT voice_ids
                      FROM filtered_data
                      WHERE voice_ids IS NOT NULL
                    )
                  ELSE
                    TRUE
                END
          )
          SELECT DISTINCT part_three.status_id 
          FROM part_three 
          JOIN part_four 
          ON part_three.account_id = part_four.id
          ORDER BY part_three.status_id DESC
          LIMIT 5;"
        end

        def selected_filters
          "selected_filters AS (
            SELECT
              (selected_filters->'source_filter'->'selected_contributor_role') AS selected_contributor_roles,
              (selected_filters->'source_filter'->'selected_voices') AS selected_voices,
              (selected_filters->'source_filter'->'selected_media') AS selected_media,
              (selected_filters->'location_filter'->'selected_countries') AS selected_countries,
              (selected_filters->'communities_filter'->'selected_communities') AS selected_communities,
              (selected_filters->'is_filter_turn_on') AS is_filter_turn_on,
              (selected_filters->'location_filter'->'is_location_filter_turn_on') AS is_location_filter_turn_on
            FROM mammoth_user_timeline_settings
            WHERE user_id = :USR_ID 
              AND (selected_filters->>'is_filter_turn_on')::boolean = true)"
        end

        def filtered_data
          "filtered_data AS (
            SELECT
              jsonb_array_elements_text(selected_contributor_roles)::integer AS contributor_role_ids,
              jsonb_array_elements_text(selected_voices)::integer AS voice_ids,
              jsonb_array_elements_text(selected_media)::integer AS media_ids,
              jsonb_array_elements_text(selected_countries) AS country_codes,
              jsonb_array_elements_text(selected_communities)::integer AS community_ids,
              jsonb_array_elements_text(is_location_filter_turn_on)::boolean AS is_location_filter_turn_on
            FROM selected_filters
          )"
        end

        def block_mute_inactive
          "block_mute_inactive AS (
            SELECT DISTINCT id
            FROM (
              SELECT DISTINCT blocks.account_id AS id 
              FROM blocks JOIN part_one on part_one.account_id = blocks.account_id  
              WHERE blocks.target_account_id = :ACC_ID
              UNION
              SELECT DISTINCT blocks.target_account_id AS id 
              FROM blocks JOIN part_one on part_one.account_id = blocks.target_account_id 
              WHERE blocks.account_id = :ACC_ID
              UNION
              SELECT DISTINCT mutes.target_account_id AS id 
              FROM mutes JOIN part_one on mutes.target_account_id = part_one.account_id
              WHERE mutes.account_id = :ACC_ID
              UNION
              SELECT DISTINCT accounts.id AS id 
              FROM accounts 
              JOIN part_one on part_one.account_id = accounts.id
              JOIN users ON accounts.id = users.account_id  
              WHERE users.is_active = false
            ) AS acc_ids
            WHERE id != :ACC_ID
          ),
          part_two AS (
            SELECT po.status_id, po.account_id
            FROM part_one as po
            LEFT JOIN block_mute_inactive as b
            ON po.account_id = b.id 
            WHERE b.id IS NULL
          )"
        end

        def bunned_status_filter
          "part_three AS (
            SELECT two.status_id as status_id, two.account_id as account_id
            FROM part_two as two
            LEFT JOIN mammoth_community_filter_statuses as filter_status 
            ON two.status_id = filter_status.status_id 
            WHERE filter_status.id IS NULL)"
        end

        def fooder_filter
          "select part_three.status_id 
            from part_three 
            ORDER BY part_three.status_id DESC
            LIMIT 5;"
        end

        def filter_rss 
          "AND s.reply = FALSE 
            AND s.community_feed_id IS NULL 
            AND s.group_id IS NULL"
        end
      end
    end
  end
end


                