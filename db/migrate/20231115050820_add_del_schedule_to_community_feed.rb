class AddDelScheduleToCommunityFeed < ActiveRecord::Migration[6.1]
  def up
    add_column :mammoth_community_feeds, :del_schedule, :integer, _skip_validate_options: true
  end

  def down
    remove_column :mammoth_community_feeds, :del_schedule
  end
end