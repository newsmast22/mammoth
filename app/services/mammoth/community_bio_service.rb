module Mammoth
  class CommunityBioService < BaseService

    def call_bio_hashtag(community_id = nil)
      tags_names = Mammoth::CommunityHashtag.where(is_incoming: true, community_id: community_id).pluck(:name)
      tag_ids = Tag.find_or_create_by_names(tags_names).map(&:id)

      Tag.joins("LEFT JOIN  statuses_tags ON tags.id = statuses_tags.tag_id")
      .select('tags.*')
      .where('tags.id IN (?)',tag_ids)
      .group('tags.id, statuses_tags.tag_id')
      .order('COUNT(statuses_tags.status_id) DESC').limit(10)
    end

    def call_admin_followed_accounts(community_id, current_account)
      remove_current_account_sql =  "AND accounts.id != #{current_account}" unless current_account.nil?
      community_admin_ids = get_admins_by_community(community_id)
      get_persons_by_admin("follows", remove_current_account_sql, community_admin_ids)
    end

    def call_editorials_accounts(community_id, current_account)
      remove_current_account_sql =  "AND accounts.id != #{current_account}" unless current_account.nil?
      community_admin_ids = get_admins_by_community(community_id)
      get_persons_by_admin("mammoth_community_editorials", remove_current_account_sql, community_admin_ids)
    end

    def call_moderator_accounts(community_id, current_account)
      remove_current_account_sql =  "AND accounts.id != #{current_account}" unless current_account.nil?
      community_admin_ids = get_admins_by_community(community_id)
      get_persons_by_admin("mammoth_community_moderators", remove_current_account_sql, community_admin_ids)
    end

    private

      def get_admins_by_community(community_id)
        Mammoth::Account.joins(users: :community_admins).where("mammoth_communities_admins.community_id = ? ",community_id).pluck(:id)
      end

      def get_persons_by_admin(tbl_name, remove_current_account_sql = nil, community_admin_ids)
        Mammoth::Account.joins("INNER JOIN #{tbl_name} ON accounts.id = #{tbl_name}.target_account_id")
        .where("#{tbl_name}.account_id IN (?) #{remove_current_account_sql}", community_admin_ids)
        .order("accounts.id desc")
      end
      
  end
end
