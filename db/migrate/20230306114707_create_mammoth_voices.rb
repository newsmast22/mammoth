class CreateMammothVoices < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_voices do |t|
      t.string :name, null: false
      t.string :slug, null: false, unique: true
      t.timestamps
    end
  end
end
