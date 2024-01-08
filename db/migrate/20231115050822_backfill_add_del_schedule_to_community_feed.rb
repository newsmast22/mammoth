class BackfillAddDelScheduleToCommunityFeed < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    Mammoth::CommunityFeed.unscoped.in_batches do |relation| 
      relation.update_all del_schedule: 24
      sleep(0.01)
    end
  end
end