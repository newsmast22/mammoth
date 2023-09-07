class AddIsIncomingToCommunityHashtags < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_community_hashtags, :is_incoming, :boolean, default: true
  end
end
