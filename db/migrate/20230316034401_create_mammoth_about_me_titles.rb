class CreateMammothAboutMeTitles < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_about_me_titles do |t|
      t.string :name, null: false
      t.string :slug, null: false, unique: true
      
      t.timestamps
    end
  end
end