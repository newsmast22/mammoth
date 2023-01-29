class AddMammothCommunitiesStatusesImage < ActiveRecord::Migration[6.1]
  def change
    add_attachment :mammoth_communities_statuses, :image
    end
end
