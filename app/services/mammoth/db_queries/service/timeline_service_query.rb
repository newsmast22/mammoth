module Mammoth
  module DbQueries
    module Service
      class TimelineServiceQuery
        def initialize(max_id, current_user, current_account, page_no)
          @param = OpenStruct.new(
            max_id: max_id,
            user_id: current_user.id,
            acc_id: current_account.id,
            page_no: page_no
          )
        end

        def following_timeline
          fetch_and_include(Mammoth::Status.following_timeline(@param))
        end

        def my_community_timeline
          fetch_and_include(Mammoth::Status.my_community_timeline(@param))
        end

        def all_timeline
          fetch_and_include(Mammoth::Status.all_timeline(@param))
        end

        def newsmast_timeline
          fetch_and_include(Mammoth::Status.newsmast_timeline(@param))
        end

        def federated_timeline
          fetch_and_include(Mammoth::Status.federated_timeline(@param))
        end

        private

        def fetch_and_include(statuses)
          @statuses = Mammoth::Status.includes(
            :reblog,
            :media_attachments,
            :active_mentions,
            :tags,
            :preloadable_poll,
            :status_stat,
            :conversation,
            account: [:user, :account_stat]
          ).where(id: statuses.pluck(:id))

          @statuses
        end
      end
    end
  end
end
