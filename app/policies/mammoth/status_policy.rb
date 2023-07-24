class Mammoth::StatusPolicy
  attr_reader :current_account, :status

  def initialize(current_account, status)
    @current_account = current_account
    @status = status
  end

  def self.policy_scope(current_account,max_id)
    acc_id = current_account.id
    
    sql_query = "SELECT statuses.*
                FROM statuses
                LEFT JOIN statuses_tags ON statuses_tags.status_id = statuses.id
                LEFT JOIN tags ON tags.id = statuses_tags.tag_id
                WHERE (:MAX_ID IS NULL OR statuses.id < :MAX_ID) 
                  AND statuses.deleted_at IS NULL 
                  AND (
                    (tags.id IN (
                      SELECT tag_follows.tag_id 
                      FROM tag_follows 
                      WHERE tag_follows.account_id = :USER_ID
                    )
                    AND statuses.account_id != :USER_ID)
                    OR statuses.account_id IN (
                      SELECT follows.target_account_id
                      FROM follows 
                      WHERE follows.account_id = :USER_ID
                    )
                  ) 
                  AND reply = FALSE
                  AND statuses.id NOT IN ( 
                    WITH acc_ids AS (
                    SELECT DISTINCT id
                    FROM (
                    SELECT account_id AS id FROM blocks WHERE account_id = :USER_ID
                      UNION
                    SELECT target_account_id AS id FROM blocks WHERE target_account_id = :USER_ID
                      UNION
                    SELECT target_account_id AS id FROM mutes WHERE account_id = :USER_ID
                        UNION
                      SELECT account_id AS id FROM accounts JOIN users ON accounts.id = users.account_id 
                                  WHERE users.is_active = false
                    ) AS acc_ids
                    WHERE id != :USER_ID
                  )
                  SELECT id
                  FROM statuses
                  WHERE id IN (
                    SELECT id FROM statuses WHERE account_id IN (SELECT * FROM acc_ids)
                  )
                  OR reblog_of_id IN (
                    SELECT id FROM statuses WHERE account_id IN (SELECT * FROM acc_ids)
                  ) 
                  );
                "
    result = Mammoth::Status.find_by_sql([sql_query, { USER_ID: acc_id,  MAX_ID: max_id }])
    return result
  end
end
