class ChangeRetryCountToPreviewCard < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      remove_column :preview_cards, :retry_counts, :integer
    }
    add_column :preview_cards, :retry_count, :integer ,default: 0
  end
end
