class Mammoth::TimelineService < BaseService
  def self.primary_timeline_filter(current_account, max_id)
    acc_id = current_account.id
    user = User.find_by(account_id: acc_id)

    userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: user.id).last
    if userTimeLineSetting.nil?
      create_userTimelineSetting()
    elsif userTimeLineSetting.selected_filters.dig('location_filter').nil?
      create_userTimelineSetting()
    elsif userTimeLineSetting.selected_filters.dig('source_filter').nil?
      create_userTimelineSetting()
    elsif userTimeLineSetting.selected_filters.dig('communities_filter').nil?
      create_userTimelineSetting()
    end
  
    if max_id.nil?
      max_id = 0
    end
    
    if max_id == 0
      condition = "statuses.id > :MAX_ID"
    else
      condition = "statuses.id < :MAX_ID"
    end

    sql_query = "SELECT statuses.id
                FROM statuses
                JOIN mammoth_communities_statuses ON statuses.id = mammoth_communities_statuses.status_id
                JOIN mammoth_communities ON mammoth_communities_statuses.community_id = mammoth_communities.id
                WHERE 
                #{condition}
                AND mammoth_communities.slug != 'breaking_news' 
                AND statuses.reply = FALSE 
                AND statuses.community_feed_id IS NULL 
                AND statuses.group_id IS NULL
                AND statuses.account_id NOT IN ( 
                    SELECT DISTINCT id
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
                    WHERE id != :ACC_ID)
                    AND statuses.account_id IN (
                        WITH selected_filters AS (
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
                          END
                      )ORDER BY statuses.created_at DESC;"

    result = Mammoth::Status.find_by_sql([sql_query, { ACC_ID: acc_id,  MAX_ID: max_id, USR_ID: user.id }])
    status_ids = result.map(&:id)
    statuses_relation = Mammoth::Status.where(id: status_ids)
    return statuses_relation
  end

  def self.create_userTimelineSetting
    userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id)
    userTimeLineSetting.destroy_all
    Mammoth::UserTimelineSetting.create!(
      user_id: current_user.id,
      selected_filters: {
        default_country: current_user.account.country,
        location_filter: {
          selected_countries: [],
          is_location_filter_turn_on: true
        },
        is_filter_turn_on: false,
        source_filter: {
          selected_media: [],
          selected_voices: [],
          selected_contributor_role: []
        },
        communities_filter: {
          selected_communities: []
        }
      }
    )
  end
end