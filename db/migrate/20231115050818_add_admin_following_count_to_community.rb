class AddAdminFollowingCountToCommunity < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_communities, :admin_following_count, :integer, default: 0
  end
end
