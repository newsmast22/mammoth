class CreateMammothCommunityFeeds < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_community_feeds do |t|
      t.references :community, null: false, foreign_key: {to_table: :mammoth_communities}
      t.string :name
      t.string :slug, null: false, unique: true
      t.string :custom_url
      t.timestamps
    end
  end
end