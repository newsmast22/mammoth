class AddIndexToStatusesTags < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :statuses_tags, :tag_id, algorithm: :concurrently
  end
  
  def down
    remove_index :statuses_tags, :tag_id
  end
  
end