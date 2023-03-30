class AddRSSLinkToStatuses < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      remove_column :statuses, :with_quotes, :boolean, default: false
    }
    add_column :statuses, :rss_link, :string
  end
end
