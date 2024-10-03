class AddIndexesToStatuses < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    execute('SET lock_timeout TO \'10s\'')

    add_index :statuses, :is_rss_content, algorithm: :concurrently
    add_index :statuses, :reply, algorithm: :concurrently
    add_index :statuses, :created_at, algorithm: :concurrently
    add_index :statuses, [:is_rss_content, :reply, :created_at], algorithm: :concurrently

    execute('RESET lock_timeout')
  end

  def down
    execute('SET lock_timeout TO \'10s\'')

    remove_index :statuses, :is_rss_content
    remove_index :statuses, :reply
    remove_index :statuses, :created_at
    remove_index :statuses, column: [:is_rss_content, :reply, :created_at]

    execute('RESET lock_timeout')
  end
end