class AddFollowersToStatuses < ActiveRecord::Migration[6.1]
  def change
    add_column :statuses, :is_only_for_followers, :boolean, default: true
  end
end
