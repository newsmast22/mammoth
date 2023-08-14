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
          @statuses = Mammoth::Status.my_community_timeline(@user_id, @max_id)
          @statuses = @statuses.filter_statuses_by_timeline_setting(@user_id)
          @statuses = @statuses.filter_block_mute_inactive_acc_id(@acc_id)
          @statuses = @statuses.filter_banned_statuses
          @statuses = @statuses.limit(5)
          if !(@statuses.nil? || @statuses.count == 0)
            @statuses = Mammoth::Status.where(id: @statuses.pluck(:id))
          end
          return @statuses
        end

        def all_old
          @statuses = Mammoth::Status.primary_timeline
          @statuses = @statuses.filter_block_mute_inactive_acc_id(@acc_id)
          @statuses = @statuses.filter_banned_statuses
          @statuses = @statuses.limit(5)
          if !(@statuses.nil? || @statuses.count == 0)
            @statuses = Mammoth::Status.where(id: @statuses.pluck(:id))
          end
          return @statuses
        end

        def all_new
          @excluded_ids = Mammoth::Status.get_block_mute_inactive_acc_id(@acc_id)
          @statuses = Mammoth::Status.primary_timeline_new(@max_id, @excluded_ids)
        end

        def newsmast_timeline 
          @statuses = Mammoth::Status.newsmast_timeline(@max_id)
          @statuses = @statuses.filter_block_mute_inactive_acc_id(@acc_id)
          @statuses = @statuses.filter_banned_statuses
          @statuses = @statuses.limit(5)
          if !(@statuses.nil? || @statuses.count == 0)
            @statuses = Mammoth::Status.where(id: @statuses.pluck(:id))
          end
          return @statuses
        end

        def federated_timeline 
          @statuses = Mammoth::Status.federated_timeline(@max_id)
          @statuses = @statuses.filter_block_mute_inactive_acc_id(@acc_id)
          @statuses = @statuses.filter_banned_statuses
          @statuses = @statuses.limit(5)
          if !(@statuses.nil? || @statuses.count == 0)
            @statuses = Mammoth::Status.where(id: @statuses.pluck(:id))
          end
          return @statuses
        end
        
      end 
    end
  end
end