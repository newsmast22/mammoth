class CreateMammothUserCommunities < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_communities_users do |t|
      t.references :community, null: false, foreign_key: {to_table: :mammoth_communities}
      t.references :user, null: false, foreign_key: true
      t.boolean :is_primary, default: false
      
      t.timestamps
    end
  end
end