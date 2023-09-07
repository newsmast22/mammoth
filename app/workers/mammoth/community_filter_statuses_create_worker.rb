module Mammoth
  class CommunityFilterStatusesCreateWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'custom_keyword_filter', retry: true, dead: true

    def perform(params = {})

      # This condition only work on create / update status manually
      if params['is_status_create'] == true

        unless params['community_id'].nil?
          params['community_id'].each do |community_id| 
            filter_statuses_by_keywords(community_id, params['status_id'])
          end
        else
          filter_statuses_by_keywords(nil, params['status_id'])
        end
        
      else
        # This condition work on create / update community filter keyword
        if params['community_filter_keyword_id'].present?
          # When update community filter keyword, delete first record.
          unban_statuses(params['community_filter_keyword_id']) if params['community_filter_keyword_request'] === "update"

          # Create community filter keyword
          filter = Mammoth::CommunityFilterKeyword.where(id: params['community_filter_keyword_id']).last
          
          if filter.present?
            if filter.is_filter_hashtag

              tag = Tag.find_by(name: filter.keyword.downcase.gsub('#', ''))
              ban_statuses(tag.statuses, filter) if tag
            else

              Mammoth::Status.where("LOWER(text) ~* ?", "\\m#{filter.keyword.downcase}\\M").find_in_batches(batch_size: 100, order: :desc) do |statuses|
              ban_statuses(tag.statuses, filter)
              end
            end
          end
          
        end
      end
    end

    private

    def ban_statuses(statuses = [], filter)
      array = statuses.map{|status| {status_id: status.id, community_filter_keyword_id: filter.id}}
      Mammoth::CommunityFilterStatus.create(array)
    end

    def unban_statuses(community_filter_keyword_id)
      Mammoth::CommunityFilterStatus.where(community_filter_keyword_id: community_filter_keyword_id)&.destroy_all
    end

    def filter_statuses_by_keywords(community_id,status_id) 

      # 1.) Global keywords check from status's text
      create_status_manually_by_user(nil, status_id) 

      # 2.) Community keywords check from status's text 
      # Note: Check only is community_id is not nil
      create_status_manually_by_user(community_id, status_id) unless community_id.nil?

    end

    def create_status_manually_by_user(community_id, status_id)

      Mammoth::CommunityFilterKeyword.where(community_id: community_id).find_in_batches(batch_size: 100, order: :desc).each do |community_filter_keywords|
        community_filter_keywords.each do |community_filter_keyword|

          is_status_banned = false

          if community_filter_keyword.is_filter_hashtag
            is_status_banned = Mammoth::Status.where(id: status_id).last.tags.where(name: community_filter_keyword.keyword.downcase.gsub("#", "")).exists?
          else
            is_status_banned = Mammoth::Status.where("LOWER(text) ~* ? AND reply = false AND id = ?", community_filter_keyword.keyword.downcase, status_id).exists?
          end
          
          if is_status_banned
            create_global_banned_statuses(community_filter_keyword,status_id)
          end
        end
      end
    end

    def create_global_banned_statuses(community_filter_Keyword,status_id)

      Mammoth::CommunityFilterStatus.where(
        status_id: status_id,
        community_filter_keyword_id: community_filter_Keyword.id
      ).first_or_create

    end

  end
end