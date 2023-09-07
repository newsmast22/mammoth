class AddIsHashtagToFilterKeywords < ActiveRecord::Migration[6.1]
  def change
    add_column :mammoth_community_filter_keywords, :is_filter_hashtag, :boolean, default: false
  end
end
