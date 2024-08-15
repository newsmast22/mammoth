class ChangeCollectionIdToBeNullableInMammothCommunities < ActiveRecord::Migration[6.1]
  def change
    change_column_null :mammoth_communities, :collection_id, true
  end
end