class CreateMammothNotificationTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_notification_tokens do |t|
      t.references :account, null: false, foreign_key: {to_table: :accounts}
      t.string :notification_token
      t.string :platform_type
      t.timestamps
    end
  end
end