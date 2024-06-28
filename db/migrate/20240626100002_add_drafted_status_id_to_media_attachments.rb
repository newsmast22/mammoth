class AddDraftedStatusIdToMediaAttachments < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    safety_assured { add_reference :media_attachments, :mammoth_drafted_status, foreign_key: { on_delete: :nullify }, index: false }
    add_index :media_attachments, :mammoth_drafted_status_id, algorithm: :concurrently
  end
end
