class AddPhoneToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :phone, :string
    add_column :users, :otp_code, :string
    add_column :users, :confirmed_otp_code, :string
    add_check_constraint :users, "email IS NOT NULL", name: "users_email_null", validate: false
  end
end
