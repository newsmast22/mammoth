class CreateMammothAppVersions < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_app_versions do |t|
      t.string :version_name, unique: true
      t.timestamps
    end
  end
end