class CreateMammothCommunityHashtag < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_community_hashtags do |t|
      t.references :community, null: false, foreign_key: {to_table: :mammoth_communities}
      t.string :hash_tags
      t.timestamps
    end
  end
end