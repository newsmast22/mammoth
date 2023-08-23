module Mammoth
  module DbQueries
    module Service
      class UserCommunityServiceQuery
        def initialize(max_id, current_user, current_account, current_community, page_no)
          
          @max_id = max_id
          @user = Mammoth::User.find(current_user.id)
          @account = current_account
          @community = current_community
          @community_slug = @community.present? || !@community.nil? ? @community.slug : nil
          @page_no = page_no
         
        end

        def all_timeline  
          if @community_slug
            @statuses = Mammoth::Status.user_community_all_timeline(@max_id, @account, @user, @community, @page_no)
            @statuses =  Mammoth::Status.includes(
                                                  :reblog, 
                                                  :media_attachments, 
                                                  :active_mentions, 
                                                  :tags, 
                                                  :preloadable_poll, 
                                                  :status_stat, 
                                                  :conversation,
                                                  account: [:user, :account_stat], 
                                                ).where(id: @statuses.pluck(:id))
          end                             
          return @statuses
        end

        def recommended_timeline 
          if @community_slug
            @statuses = Mammoth::Status.user_community_recommended_timeline(@max_id, @account, @user, @community, @page_no)
            @statuses =  Mammoth::Status.includes(
                                                  :reblog, 
                                                  :media_attachments, 
                                                  :active_mentions, 
                                                  :tags, 
                                                  :preloadable_poll, 
                                                  :status_stat, 
                                                  :conversation,
                                                  account: [:user, :account_stat], 
                                                ).where(id: @statuses.pluck(:id))
          end
          return @statuses
        end
      end 
    end 
  end 
end
    
