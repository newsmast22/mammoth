class CreateMammothSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_settings do |t|
      t.string :thing_type
      t.bigint :thing_type_id
      t.jsonb :settings
      t.timestamps
    end
  end
end
