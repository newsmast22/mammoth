class CreateMonitoringStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :monitoring_statuses do |t|
      t.integer :end_point_id
      t.json :end_point_response
      t.boolean :is_operational, default: false
      t.string :monitoring_batch, null: false, unique: true

      t.timestamps
    end
    add_index :monitoring_statuses, :end_point_id
  end
end
