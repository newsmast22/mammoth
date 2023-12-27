class AddBotAccountToCommunity < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_communities, :bot_account, :string
  end
end