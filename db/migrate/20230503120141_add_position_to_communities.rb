class AddPositionToCommunities < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_communities, :position, :integer
  end
end
