class ChangeCommunityHashtag < ActiveRecord::Migration[6.1]
  safety_assured {
    remove_column :mammoth_community_hashtags, :hash_tags, :string
  }
  add_column :mammoth_community_hashtags, :hashtag, :string
end
