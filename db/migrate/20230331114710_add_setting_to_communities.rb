class AddSettingToCommunities < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_communities, :is_country_filter_on, :boolean, default: true
  end
end
