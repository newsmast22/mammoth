class AddCountryDobToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :country, :string
    add_column :accounts, :dob, :string 
  end
end
