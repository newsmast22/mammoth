class ChangeCommunityStatusDefaultNull < ActiveRecord::Migration[6.1]
  def change
    change_column_null :mammoth_communities_statuses, :community_id, true
  end
end
