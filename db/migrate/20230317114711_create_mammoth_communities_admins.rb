class CreateMammothCommunitiesAdmins < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_communities_admins do |t|
      t.references :community, null: false, foreign_key: {to_table: :mammoth_communities}
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
