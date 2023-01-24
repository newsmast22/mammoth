class CreateMammothCommunities < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_communities do |t|
      t.string :name, null: false
      t.string :slug, null: false, unique: true
      t.attachment :image
      t.string :description
      t.references :collection, null: false, foreign_key: {to_table: :mammoth_collections}
      t.timestamps
    end
  end
end
