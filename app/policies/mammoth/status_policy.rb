class Mammoth::StatusPolicy
  attr_reader :current_account, :current_user, :status

  def initialize(current_account, current_user, status)
    @current_account = current_account
    @current_user = current_user
    @status = status
  end

  def self.policy_scope(current_account, current_user, max_id)
    acc_id = current_account.id
    usr_id = current_user.id

    userTimeLineSetting = Mammoth::UserTimelineSetting.where(user_id: current_user.id).last
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
    LEFT JOIN statuses_tags ON statuses_tags.status_id = statuses.id
    LEFT JOIN tags ON tags.id = statuses_tags.tag_id
    WHERE #{condition}
      AND statuses.deleted_at IS NULL 
      AND (
        (tags.id IN (
          SELECT tag_follows.tag_id 
          FROM tag_follows 
          WHERE tag_follows.account_id = :ACC_ID
        )
        AND statuses.account_id != :ACC_ID)
        OR statuses.account_id IN (
          SELECT follows.target_account_id
          FROM follows 
          WHERE follows.account_id = :ACC_ID
        )
      ) 
      AND reply = FALSE
      AND statuses.account_id IN (
        WITH selected_filters AS (
          SELECT
            (selected_filters->'source_filter'->'selected_contributor_role') AS selected_contributor_roles,
            (selected_filters->'source_filter'->'selected_voices') AS selected_voices,
            (selected_filters->'source_filter'->'selected_media') AS selected_media,
            (selected_filters->'location_filter'->'selected_countries') AS selected_countries,
            (selected_filters->'communities_filter'->'selected_communities') AS selected_communities
          FROM mammoth_user_timeline_settings
          WHERE user_id = :USR_ID
        ),
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
      )
      AND statuses.id NOT IN ( 
        WITH acc_ids AS (
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
          WHERE id != :ACC_ID
        )
        SELECT id
        FROM statuses
        WHERE id IN (
          SELECT id FROM statuses WHERE account_id IN (SELECT * FROM acc_ids)
        )
        OR reblog_of_id IN (
          SELECT id FROM statuses WHERE account_id IN (SELECT * FROM acc_ids)
        ) 
      ) ORDER BY statuses.created_at DESC;"
    
    result = Mammoth::Status.find_by_sql([sql_query, { USR_ID: usr_id, ACC_ID: acc_id,  MAX_ID: max_id }])

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
