class CreateMammothDraftedStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :mammoth_drafted_statuses do |t|
      t.belongs_to :account, foreign_key: { on_delete: :cascade }
      t.jsonb :params
      t.timestamps
    end
  end
end