class AddAccountFollowFlag < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :is_recommended, :boolean, default: false
    add_column :accounts, :is_popular, :boolean, default: false
  end
end
