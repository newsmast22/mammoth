class AddPositionToCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_collections, :position, :integer
  end
end
