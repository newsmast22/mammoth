module Mammoth
  module DbQueries
    module Service
      class TimelineServiceNew
        def initialize(max_id,current_user,current_account, page_no)
          @max_id = max_id
          @user_id = current_user.id
          @acc_id = current_account.id
          @page_no = page_no
        end

        def following_timeline 
          @statuses = Mammoth::Status.following_timeline(@user_id, @acc_id, @max_id, @page_no)
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
          return @statuses
        end

        def my_community_timeline 
          @excluded_ids = Mammoth::Status.get_block_mute_inactive_acc_id(@acc_id)
          @statuses = Mammoth::Status.my_community_timeline(@user_id, @max_id, @excluded_ids, @page_no)
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
          return @statuses
        end

        def all_timeline
          @excluded_ids = Mammoth::Status.get_block_mute_inactive_acc_id(@acc_id)
          @statuses = Mammoth::Status.all_timeline(@max_id, @excluded_ids, @page_no)
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
          return @statuses
        end

        def newsmast_timeline 
          @excluded_ids = Mammoth::Status.get_block_mute_inactive_acc_id(@acc_id)
          @statuses = Mammoth::Status.newsmast_timeline(@max_id, @excluded_ids, @page_no)
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
          return @statuses
        end

        def federated_timeline 
          @statuses = Mammoth::Status.federated_timeline(@max_id, @page_no)
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
          return @statuses
        end
      end 
    end
  end
end