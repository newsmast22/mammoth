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
          puts "********** DB Host Swithcing in my_community_timeline 2************"
          puts ActiveRecord::Base.connection_db_config.database

          @statuses = Mammoth::Status.my_community_timeline(@user_id, @max_id)
          @statuses = @statuses.filter_statuses_by_timeline_setting(@user_id)
          @statuses = @statuses.filter_block_mute_inactive_acc_id(@user_id)
          @statuses = @statuses.filter_banned_statuses
          @statuses = @statuses.limit(5)
        end

        def primary_timeline 
          puts "********** DB Host Swithcing in primary_timeline 2************"
          puts ActiveRecord::Base.connection_db_config.database

          @statuses = Mammoth::Status.primary_timeline(@max_id)
          @statuses = @statuses.filter_block_mute_inactive_acc_id(@user_id)
          @statuses = @statuses.filter_banned_statuses
          @statuses = @statuses.limit(5)
        end

        def newsmast_timeline 
          puts "********** DB Host Swithcing in newsmast_timeline 2************"
          puts ActiveRecord::Base.connection_db_config.database
        
          @statuses = Mammoth::Status.newsmast_timeline(@max_id)
          @statuses = @statuses.filter_block_mute_inactive_acc_id(@user_id)
          @statuses = @statuses.filter_banned_statuses
          @statuses = @statuses.limit(5)
        end

        def federated_timeline 
          puts "********** DB Host Swithcing in federated_timeline 2************"
          puts ActiveRecord::Base.connection_db_config.database

          @statuses = Mammoth::Status.federated_timeline(@max_id)
          @statuses = @statuses.filter_block_mute_inactive_acc_id(@user_id)
          @statuses = @statuses.filter_banned_statuses
          @statuses = @statuses.limit(5)
        end
        
      end 
    end
  end
end