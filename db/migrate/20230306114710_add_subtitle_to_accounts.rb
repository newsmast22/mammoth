class AddSubtitleToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :subtitle_id, :integer 
  end
end
