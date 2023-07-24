class AddTranslateTextToStatuses < ActiveRecord::Migration[6.1]
  def change
    add_column :statuses, :translated_text, :string
  end
end
