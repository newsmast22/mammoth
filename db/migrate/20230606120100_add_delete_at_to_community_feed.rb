class AddDeleteAtToCommunityFeed < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_community_feeds, :delete_at, :datetime
  end
end
