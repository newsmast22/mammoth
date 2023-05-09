class AddPreviewCardToStatuses < ActiveRecord::Migration[6.1]
  def change
    add_column :statuses, :is_preview_card, :boolean, default: true
  end
end
