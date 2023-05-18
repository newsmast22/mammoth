class AddCheckAccountCompleteToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :is_account_setup_finished, :boolean, default: false
    add_column :users, :step, :string
  end
end
