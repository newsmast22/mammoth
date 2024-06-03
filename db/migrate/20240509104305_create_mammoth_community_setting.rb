class CreateMammothCommunitySetting < ActiveRecord::Migration[7.1]
  def change
    create_table :mammoth_community_amplifier_settings do |t|
      t.references :user, foreign_key: true
      t.references :mammoth_community, foreign_key: true
      t.jsonb :amplifier_setting, default: {}
      t.boolean :is_turn_on, default: false
      t.timestamps
    end
  end
end
