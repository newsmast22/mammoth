class AddAccountIdBigintToCommunityFeeds < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      remove_column :mammoth_community_feeds, :account_id, :integer
    }
    add_column :mammoth_community_feeds, :account_id, :bigint
  end
end
