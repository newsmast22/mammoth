class AddIndexesToStatuses < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :statuses, :is_rss_content, algorithm: :concurrently
    add_index :statuses, :reply, algorithm: :concurrently
    add_index :statuses, :created_at, algorithm: :concurrently
    add_index :statuses, [:is_rss_content, :reply, :created_at], algorithm: :concurrently
  end

  def down
    remove_index :statuses, :is_rss_content
    remove_index :statuses, :reply
    remove_index :statuses, :created_at
    remove_index :statuses, column: [:is_rss_content, :reply, :created_at]
  end
end

