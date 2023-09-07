class AddNameToCommunityHashtags < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_community_hashtags, :name, :string
  end
end
