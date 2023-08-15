class AddIndexes < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :users, :is_active, where: 'is_active IS FALSE', algorithm: :concurrently
    add_index :blocks, :account_id, algorithm: :concurrently
  end
  
  def down
    remove_index :users, :is_active
    remove_index :blocks, :account_id
  end
end
  