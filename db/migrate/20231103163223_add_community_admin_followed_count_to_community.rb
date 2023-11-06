class AddCommunityAdminFollowedCountToCommunity < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_communities, :community_admin_followed_count, :integer, default: 0
  end
end
