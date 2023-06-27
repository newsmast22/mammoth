class AddGroupIdToStatuses < ActiveRecord::Migration[6.1]
  def change
    add_column :statuses, :group_id, :bigint ,null: true, default: nil
  end
end
