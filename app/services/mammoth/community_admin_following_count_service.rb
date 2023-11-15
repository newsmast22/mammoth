module Mammoth
  class CommunityAdminFollowingCountService < BaseService
    def call(account_id)
      @account_id = account_id
  
      admin_following_counter!
    end
  
    private
  
    def admin_following_counter!
      community_ids = Mammoth::User.joins(:account, :community_admins).where(users: { role_id: 4 }, accounts: { id: @account_id }).pluck(:community_id)
      communities = Mammoth::Community.where(id: community_ids)
      communities.each do |community|
        user_ids = Mammoth::CommunityAdmin.where(community_id: community.id).pluck(:user_id)
        account_ids = Mammoth::User.where(id: user_ids).pluck(:account_id)
        followed_count = Follow.where(account_id: account_ids).pluck(:target_account_id).uniq.count
        community.update(admin_following_count: followed_count)
      end
    end
    
  end
end
