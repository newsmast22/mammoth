class BackFillAddViaNewsmastApiToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    User.unscoped.in_batches do |relation| 
      relation.update_all via_newsmast_api: false
      sleep(0.01)
    end
  end

end
