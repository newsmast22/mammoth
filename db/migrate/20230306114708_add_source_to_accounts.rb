class AddSourceToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :contributor_role_id, :integer 
    add_column :accounts, :media_id, :integer 
    add_column :accounts, :voice_id, :integer 
  end
end
