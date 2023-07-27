module Mammoth
  module DbQueries
    module Common::StatusAuthorizeQuery
      def self.select_acc_by_block_mute_delete
        "SELECT DISTINCT id
          FROM (
            SELECT account_id AS id FROM blocks WHERE account_id = :ACC_ID
              UNION
            SELECT target_account_id AS id FROM blocks WHERE target_account_id = :ACC_ID
              UNION
            SELECT target_account_id AS id FROM mutes WHERE account_id = :ACC_ID
              UNION
            SELECT account_id AS id FROM accounts JOIN users ON accounts.id = users.account_id 
                                WHERE users.is_active = false
          ) AS acc_ids
          WHERE id != :ACC_ID"
      end
      
      def self.select_acc_by_user_filter
        "WITH selected_filters AS (
          SELECT
            (selected_filters->'source_filter'->'selected_contributor_role') AS selected_contributor_roles,
            (selected_filters->'source_filter'->'selected_voices') AS selected_voices,
            (selected_filters->'source_filter'->'selected_media') AS selected_media,
            (selected_filters->'location_filter'->'selected_countries') AS selected_countries,
            (selected_filters->'communities_filter'->'selected_communities') AS selected_communities
          FROM mammoth_user_timeline_settings
          WHERE user_id = :USR_ID ),
        filtered_data AS (
          SELECT
            jsonb_array_elements_text(selected_contributor_roles)::integer AS contributor_role_ids,
            jsonb_array_elements_text(selected_voices)::integer AS voice_ids,
            jsonb_array_elements_text(selected_media)::integer AS media_ids,
            jsonb_array_elements_text(selected_countries) AS country_codes,
            jsonb_array_elements_text(selected_communities)::integer AS community_ids
          FROM selected_filters
        )
        SELECT accounts.id AS id
        FROM accounts
        WHERE 
          CASE
            WHEN (SELECT COUNT(filtered_data.country_codes) FROM filtered_data ) > 0 THEN
              country = ANY (
                              SELECT country_codes
                              FROM filtered_data
                              WHERE country_codes IS NOT NULL
                            )
            ELSE
              TRUE
          END
        INTERSECT
        SELECT accounts.id AS id
        FROM accounts
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
        SELECT accounts.id AS id
        FROM accounts
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
        SELECT accounts.id AS id
        FROM accounts
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
          END"
      end
    end
  end 
end