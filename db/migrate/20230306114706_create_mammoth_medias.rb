class CreateMammothMedias < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_medias do |t|
      t.string :name, null: false
      t.string :slug, null: false, unique: true
      t.timestamps
    end
  end
end
