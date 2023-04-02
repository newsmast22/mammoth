class DropCommunityAdminSettings < ActiveRecord::Migration[6.1]
  def change
    drop_table :mammoth_community_admin_settings
  end
end
