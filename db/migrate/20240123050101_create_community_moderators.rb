class CreateCommunityModerators < ActiveRecord::Migration[6.1]

  def change
    create_table :mammoth_community_moderators do |t|
      t.bigint :account_id, null: false
      t.bigint :target_account_id, null: false

      t.timestamps
    end
    add_index :mammoth_community_moderators, [:account_id, :target_account_id], unique: true, name: 'index_moderators_on_account_and_target_account'
  end
  
end