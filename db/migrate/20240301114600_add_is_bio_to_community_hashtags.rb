class AddIsBioToCommunityHashtags < ActiveRecord::Migration[6.1]
  def up
    add_column :mammoth_community_hashtags, :is_bio, :boolean, _skip_validate_options: true
    change_column_default :mammoth_community_hashtags, :is_bio, false
  end

  def down
    remove_column :mammoth_community_hashtags, :is_bio
  end
end
