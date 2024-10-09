class AddIndexesToStatuses < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      execute('SET lock_timeout TO \'10s\'')

      add_index_if_not_exists :statuses, :is_rss_content, algorithm: :concurrently
      add_index_if_not_exists :statuses, :reply, algorithm: :concurrently
      add_index_if_not_exists :statuses, :created_at, algorithm: :concurrently
      add_index_if_not_exists :statuses, [:is_rss_content, :reply, :created_at], algorithm: :concurrently

      execute('RESET lock_timeout')
    end
  end

  def down
    safety_assured do
      execute('SET lock_timeout TO \'10s\'')

      remove_index_if_exists :statuses, :is_rss_content
      remove_index_if_exists :statuses, :reply
      remove_index_if_exists :statuses, :created_at
      remove_index_if_exists :statuses, column: [:is_rss_content, :reply, :created_at]

      execute('RESET lock_timeout')
    end
  end

  private

  def add_index_if_not_exists(table_name, column_name, options = {})
    unless index_exists?(table_name, column_name)
      add_index(table_name, column_name, options)
    end
  end

  def remove_index_if_exists(table_name, column_name, options = {})
    if index_exists?(table_name, column_name)
      remove_index(table_name, column_name, options)
    end
  end
end
