class AddFkToCommunityStatuses < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key "mammoth_communities_statuses", "statuses"

    add_foreign_key "mammoth_communities_statuses", "statuses", on_delete: :cascade, validate: false
  end
end