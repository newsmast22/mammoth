class ChangeAccountFiledArrayToInteger < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      remove_column :accounts, :contributor_role_id, :integer, array:true, default: []
    }
    safety_assured {
      remove_column :accounts, :media_id, :integer, array:true, default: []
    }
    safety_assured {
      remove_column :accounts, :voice_id, :integer, array:true, default: []
    }

    add_column :accounts, :contributor_role_id, :integer
    add_column :accounts, :media_id, :integer
    add_column :accounts, :voice_id, :integer
  end
end
