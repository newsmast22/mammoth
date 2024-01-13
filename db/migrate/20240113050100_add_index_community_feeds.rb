class AddIndexCommunityFeeds < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :mammoth_community_feeds, :account_id, algorithm: :concurrently
  end
  
  def down
    remove_index :mammoth_community_feeds, :account_id
  end
end