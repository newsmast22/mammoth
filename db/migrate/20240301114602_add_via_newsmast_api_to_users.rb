class AddViaNewsmastApiToUsers < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :via_newsmast_api, :boolean, _skip_validate_options: true
    change_column_default :users, :via_newsmast_api, false
  end

  def down
    remove_column :users, :via_newsmast_api
  end
end
