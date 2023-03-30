class AddAccountIdToCommunityFeeds < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_community_feeds, :account_id, :integer
  end
end
