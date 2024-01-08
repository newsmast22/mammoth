class SetDefaultDelScheduleToCommunityFeed < ActiveRecord::Migration[6.1]
  def change
    change_column_default :mammoth_community_feeds, :del_schedule, 24
  end
end