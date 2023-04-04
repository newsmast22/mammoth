class AddCommunityFeedToStatus < ActiveRecord::Migration[6.1]
  def change
    add_reference :statuses, :community_feed, null: true, default: nil, index: false
  end
end
