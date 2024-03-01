class BackFillAddIsBioToCommunityHashtags < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    Mammoth::CommunityHashtag.unscoped.in_batches do |relation| 
      relation.update_all is_bio: false
      sleep(0.01)
    end
  end

end
