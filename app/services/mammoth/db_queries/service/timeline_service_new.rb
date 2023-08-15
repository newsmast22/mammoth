module Mammoth
  module DbQueries
    module Service
      class TimelineServiceNew
        def initialize(max_id,current_user,current_account)
          @max_id = max_id
          @user_id = current_user.id
          @acc_id = current_account.id
        end

        def my_community_timeline 
          ActiveRecord::Base.connected_to(role: :reading) do 
            @excluded_ids = Mammoth::Status.get_block_mute_inactive_acc_id(@acc_id)
            @statuses = Mammoth::Status.includes(
                                                  :reblog, 
                                                  :media_attachments, 
                                                  :active_mentions, 
                                                  :tags, 
                                                  :preloadable_poll, 
                                                  :status_stat, 
                                                  :conversation,
                                                  account: [:user, :account_stat], 
                                                ).my_community_timeline(@user_id, @max_id, @excluded_ids)
          end
          return @statuses
        end

        def all_timeline
          ActiveRecord::Base.connected_to(role: :reading) do 
            @excluded_ids = Mammoth::Status.get_block_mute_inactive_acc_id(@acc_id)
            @statuses = Mammoth::Status.includes(
                                                  :reblog, 
                                                  :media_attachments, 
                                                  :active_mentions, 
                                                  :tags, 
                                                  :preloadable_poll, 
                                                  :status_stat, 
                                                  :conversation,
                                                  account: [:user, :account_stat], 
                                                ).all_timeline(@max_id, @excluded_ids)
          end
          return @statuses
        end

        def newsmast_timeline 
          ActiveRecord::Base.connected_to(role: :reading) do 
            @excluded_ids = Mammoth::Status.get_block_mute_inactive_acc_id(@acc_id)
            @statuses = Mammoth::Status.includes(
                                                :reblog, 
                                                :media_attachments, 
                                                :active_mentions, 
                                                :tags, 
                                                :preloadable_poll, 
                                                :status_stat, 
                                                :conversation,
                                                account: [:user, :account_stat], 
                                              ).newsmast_timeline(@max_id, @excluded_ids)
          end
          return @statuses
        end

        def federated_timeline 
          ActiveRecord::Base.connected_to(role: :reading) do 
            @excluded_ids = Mammoth::Status.get_block_mute_inactive_acc_id(@acc_id)
            @statuses = Mammoth::Status.includes(
                                                :reblog, 
                                                :media_attachments, 
                                                :active_mentions, 
                                                :tags, 
                                                :preloadable_poll, 
                                                :status_stat, 
                                                :conversation,
                                                account: [:user, :account_stat], 
                                              ).federated_timeline(@max_id)
          end
          return @statuses
        end
      end 
    end
  end
end