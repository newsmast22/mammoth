class AddIndexStatuses < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :statuses, :community_feed_id, algorithm: :concurrently
  end
  
  def down
    remove_index :statuses, :community_feed_id
  end
end