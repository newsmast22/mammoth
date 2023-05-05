class AddWaitlistToUsers < ActiveRecord::Migration[6.1]
  def change
    add_reference :users, :wait_list, null: true, default: nil, index: false
  end
end
