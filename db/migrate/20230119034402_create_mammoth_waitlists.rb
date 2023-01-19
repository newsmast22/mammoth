class CreateMammothWaitlists < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_wait_lists do |t|
      t.string :email
      t.string :invitation_code, null: false, unique: true
      t.string :role
      t.integer :contributor_role_id
      t.string :description
      t.boolean :is_invitation_code_used, default: false
      
      t.timestamps
    end
  end
end