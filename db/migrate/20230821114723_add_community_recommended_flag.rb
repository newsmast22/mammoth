class AddCommunityRecommendedFlag < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_communities, :is_recommended, :boolean, default: false
  end
end
