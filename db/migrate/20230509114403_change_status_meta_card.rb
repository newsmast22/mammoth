class ChangeStatusMetaCard < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      remove_column :statuses, :is_preview_card, :boolean, default: true
    }
    add_column :statuses, :is_meta_preview, :boolean, default: false
  end
end
