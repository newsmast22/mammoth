class ValidateAddFkToCommunityStatuses < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :mammoth_communities_statuses, :statuses
  end
end