class CreateMammothCommunityAdminSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_community_admin_settings do |t|
      t.references :community_admin, null: false, foreign_key: {to_table: :mammoth_communities_admins}
      t.boolean :is_country_filter_on, default: true
      t.timestamps
    end
  end
end