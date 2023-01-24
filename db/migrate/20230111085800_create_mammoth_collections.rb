class CreateMammothCollections < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_collections do |t|
      t.string :name, null: false
      t.string :slug, null: false, unique: true
      t.attachment :image
      
      t.timestamps
    end
  end
end