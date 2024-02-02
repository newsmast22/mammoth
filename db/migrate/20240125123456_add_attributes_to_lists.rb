class AddAttributesToLists < ActiveRecord::Migration[7.1]
  def up
    add_attachment :lists, :list_avatar
    add_attachment :lists, :list_header
    add_column :lists, :description, :string
  end

  def down
    remove_attachment :lists, :list_avatar
    remove_attachment :lists, :list_header
    remove_column :lists, :description
  end
end
