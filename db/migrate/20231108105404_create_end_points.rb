class CreateEndPoints < ActiveRecord::Migration[6.1]
  def change
    create_table :end_points do |t|
      t.string :name
      t.string :end_point_url
      t.string :http_method
      t.string :access_token
      t.integer :max_active

      t.timestamps
    end
  end
end
