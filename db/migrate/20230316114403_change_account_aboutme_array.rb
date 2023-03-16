class ChangeAccountAboutmeArray < ActiveRecord::Migration[6.1]
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

    add_column :accounts, :about_me_title_option_ids, :integer, array:true, default: []
   
  end
end
