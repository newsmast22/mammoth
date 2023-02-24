class CreateMammothUserTimelineSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_user_timeline_settings do |t|
      t.integer :user_id,null: false, foreign_key: true
      t.jsonb :selected_filters      
      t.timestamps
    end
  end
end