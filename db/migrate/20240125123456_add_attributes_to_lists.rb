class AddAttributesToLists < ActiveRecord::Migration[7.1]
  def up
    add_attachment :lists, :list_avatar
    add_attachment :lists, :list_header
    add_column :lists, :description, :string
    add_column :lists, :hide_from_home, :boolean, _skip_validate_options: true
    change_column_default :lists, :hide_from_home, from: nil, to: false
  end

  def down
    remove_attachment :lists, :list_avatar
    remove_attachment :lists, :list_header
    remove_column :lists, :description
    remove_column :lists, :hide_from_home
  end
end
