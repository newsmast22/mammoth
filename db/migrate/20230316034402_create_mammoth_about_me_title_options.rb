class CreateMammothAboutMeTitleOptions < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_about_me_title_options do |t|
      t.references :about_me_title, null: false, foreign_key: {to_table: :mammoth_about_me_titles}
      t.string :name, null: false
      t.string :slug, null: false, unique: true
      
      t.timestamps
    end
  end
end