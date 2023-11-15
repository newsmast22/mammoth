class ChangeCommunityAdminFollowCountToParticipantsCount < ActiveRecord::Migration[6.1]
  safety_assured do
    remove_column :mammoth_communities, :community_admin_followed_count, :integer
  end

  add_column :mammoth_communities, :participants_count, :integer, default: 0
end
