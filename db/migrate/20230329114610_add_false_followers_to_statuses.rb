class AddFalseFollowersToStatuses < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      remove_column :statuses, :is_only_for_followers, :boolean, default: true
    }
    add_column :statuses, :is_only_for_followers, :boolean, default: false
    add_column :statuses, :is_rss_content, :boolean, default: false
  end
end
