class AddRetryCountToPreviewCard < ActiveRecord::Migration[6.1]
  def change
    add_column :preview_cards, :retry_counts, :integer
  end
end
