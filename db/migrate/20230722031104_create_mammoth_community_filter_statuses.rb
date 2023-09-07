class CreateMammothCommunityFilterStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_community_filter_statuses do |t|
      t.references :community_filter_keyword, null: false, foreign_key: {to_table: :mammoth_community_filter_keywords}, index: { name: 'index_mammoth_community_filter_keyword_id' }
      t.references :status, null: false, foreign_key: {to_table: :statuses}
      t.timestamps
    end

  end
end