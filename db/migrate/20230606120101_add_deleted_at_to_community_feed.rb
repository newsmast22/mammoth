class AddDeletedAtToCommunityFeed < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      remove_column :mammoth_community_feeds, :delete_at, :datetime
    }
    add_column :mammoth_community_feeds, :deleted_at, :datetime
  end
end
