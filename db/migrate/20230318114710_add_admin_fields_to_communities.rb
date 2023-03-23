class AddAdminFieldsToCommunities < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_communities, :is_country_filtering, :boolean, default: false
    add_column :mammoth_communities, :fields, :jsonb
    add_attachment :mammoth_communities, :header
  end
end
