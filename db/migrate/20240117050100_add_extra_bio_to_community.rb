class AddExtraBioToCommunity < ActiveRecord::Migration[6.1]

  def change
    add_column :mammoth_communities, :bot_account_info, :string
    add_column :mammoth_communities, :guides, :jsonb
  end
  
end