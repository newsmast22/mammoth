class CreateMammothCommunityFilterKeywords < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_community_filter_keywords do |t|
      t.references :account, null: false, foreign_key: {to_table: :accounts}
      t.references :community, null: true, default: nil, index: false, foreign_key: {to_table: :mammoth_communities}
      t.string :keyword
      t.timestamps
    end
  end
end