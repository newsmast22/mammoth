class AddStatusTextCount < ActiveRecord::Migration[6.1]
  def change
    add_column :statuses, :text_count, :integer
  end
end
