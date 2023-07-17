class CreateMammothAppVersionHistorys < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_app_version_historys do |t|
      t.references :app_version, null: false, foreign_key: {to_table: :mammoth_app_versions}
      t.string :os_type
      t.boolean :deprecated, default: false
      t.string :link_url
      t.timestamps
    end
  end
end