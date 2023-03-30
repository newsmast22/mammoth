class AddRSSLinkToStatuses < ActiveRecord::Migration[6.1]
  def change
    add_column :statuses, :rss_link, :string
  end
end
