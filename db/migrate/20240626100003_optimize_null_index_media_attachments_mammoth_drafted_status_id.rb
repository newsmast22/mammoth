# frozen_string_literal: true

require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class OptimizeNullIndexMediaAttachmentsMammothDraftedStatusId < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    update_index :media_attachments, 'index_media_attachments_on_mammoth_drafted_status_id', :mammoth_drafted_status_id, where: 'mammoth_drafted_status_id IS NOT NULL'
  end

  def down
    update_index :media_attachments, 'index_media_attachments_on_mammoth_drafted_status_id', :mammoth_drafted_status_id
  end
end
