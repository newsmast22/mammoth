module Mammoth
  class CommunityFilterStatusesCreateWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'custom_keyword_filter', retry: true, dead: true

    def perform(params = {})

      if params['is_status_create'] == true

        unless params['community_id'].nil?
          params['community_id'].each do |community_id| 
            Mammoth::CommunityFilterKeyword.new.filter_statuses_by_keywords(community_id, params['status_id'])
          end
        else
          Mammoth::CommunityFilterKeyword.new.filter_statuses_by_keywords(nil, params['status_id'])
        end
        
      else
        unban_statuses(params['community_filter_keyword_id']) if params['community_filter_keyword_request'] === "update" || params['community_filter_keyword_request'] === "delete"

        ban_statuses(params['community_filter_keyword_id']) unless params['community_filter_keyword_request'] === "delete"
      end

    end

    private

    def ban_statuses(community_filter_keyword_id)

      filter = Mammoth::CommunityFilterKeyword.where(id: community_filter_keyword_id).last

      if filter.present?
        
        # If keyword included #example, remove # and result will be example
        cleaned_keyword = filter.keyword.gsub("#", "")

        Mammoth::Status.where("text ~* ?", "\\m#{cleaned_keyword}\\M").find_in_batches(batch_size: 100) do |statuses|
          array = statuses.map{|status| {status_id: status.id, community_filter_keyword_id: filter.id}}
          Mammoth::CommunityFilterStatus.create(array)
        end
      end
    
    end

    def unban_statuses(community_filter_keyword_id)

      Mammoth::CommunityFilterStatus.where(community_filter_keyword_id: community_filter_keyword_id)&.destroy_all

    end

  end
end