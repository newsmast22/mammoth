module Mammoth
  module DbQueries
    module Service
      class UserCommunityServiceQuery
        def initialize(max_id, current_user, current_account, current_community)
          @max_id = max_id
          @user_id = current_user.id
          @acc_id = current_account.id
          @community_slug = current_community.slug
          @community_admins_acc_ids = Mammoth::CommunityAdmin.joins(:user).where(community_id: @community_id).pluck('users.account_id')
          @acc_ids = (@community_admins_acc_ids.push(@acc_id)).uniq
        end

        def all_timeline  
          @statuses = Mammoth::Status.includes(
                                                :reblog, 
                                                :media_attachments, 
                                                :active_mentions, 
                                                :tags, 
                                                :preloadable_poll, 
                                                :status_stat, 
                                                :conversation,
                                                account: [:user, :account_stat]
                                              ).user_community_all_timeline(@max_id, @acc_ids, @user_id, @community_slug)

          return @statuses
        end

        def recommended_timeline 
          @statuses = Mammoth::Status.includes(
                                                :reblog, 
                                                :media_attachments, 
                                                :active_mentions, 
                                                :tags, 
                                                :preloadable_poll, 
                                                :status_stat, 
                                                :conversation,
                                                account: [:user, :account_stat], 
                                              ).following_timeline(@user_id, @acc_id, @max_id)
        
          return @statuses
        end
      end 
    end 
  end 
end
    
