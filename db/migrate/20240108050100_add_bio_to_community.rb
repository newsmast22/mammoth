class AddBioToCommunity < ActiveRecord::Migration[6.1]

  def change
    add_column :mammoth_communities, :bio, :string
  end
end