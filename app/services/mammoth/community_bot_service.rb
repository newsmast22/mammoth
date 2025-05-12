class Mammoth::CommunityBotService < BaseService
  include FormattingHelper
  def call(community_id, status_id)

    @status = Mammoth::Status.find(status_id)

    @community_ids = []

    if community_id.nil?
      find_matching_communities_from_hashtags
      find_form_follower_community_admins

      @community_ids.each do |id|
        boost_by_community_bot(id)
      end

    else
      boost_by_community_bot(community_id)
    end
  end

  private

    def find_form_follower_community_admins
      # Looping community to fetch followed accounts by community admin
      get_admins_from_follow.each do |community_admin|
        communities = Mammoth::Account.find(community_admin.id).get_owned_communities

        # Looping community
        @community_ids.concat(communities.ids)
      end
      @community_ids.uniq
    end

    def boost_by_community_bot(community_id)
      community_bot_account = get_community_bot_account(community_id)
      return false if community_bot_account.nil? || @status.banned? || is_blocked_by_admins?(community_id, @status.account_id) || @status.reply?

      post_url = get_post_url
      bot_lamda_service = Mammoth::BoostLamdaCommunityBotService.new
      boost_status = bot_lamda_service.boost_status(community_bot_account, @status.id, post_url.to_s)
      return true if boost_status["statusCode"] == 200
      false
    end

    def find_matching_communities_from_hashtags
      return if @status.nil? || @status.tags.blank?

      tag_names = @status.tags.map(&:name)

      tag_names.each do |tag|
        @community_ids.concat(
          Rails.cache.fetch("community_hashtags/#{tag}", expires_in: 1.day) do
            Mammoth::CommunityHashtag
              .where("LOWER(name) = ?", tag)
              .where(is_incoming: true)
              .pluck(:community_id)
          end
        )
      end
      @community_ids.uniq!
    end

    def get_post_url
      username = @status.account.pretty_acct
      "https://newsmast.social/@#{username}/#{@status.id}"
    end

    def get_community_bot_account(community_id)
      Mammoth::Community.where(id: community_id).last&.bot_account
    end

    def is_blocked_by_admins?(community_id, account_id)
      target_account_ids = (
                            Block
                            .where(account_id: Mammoth::Account
                            .joins(users: :community_admins)
                            .where(community_admins: { community_id: community_id}, users: { role_id: 4 })
                            .pluck(:id))
                            .pluck(:target_account_id) + Mute
                            .where(account_id: Mammoth::Account
                            .joins(users: :community_admins)
                            .where(community_admins: { community_id: community_id}, users: { role_id: 4 })
                            .pluck(:id))
                            .pluck(:target_account_id)
                            ).uniq
      
      return true if target_account_ids.include?(account_id.to_i)
      false
    end

    def get_admins_from_follow
      Mammoth::Account.where(id: get_followed_admins)
    end

    def get_followed_admins
      Follow.where(account_id: get_all_community_admins.pluck(:id), target_account_id: @status.account_id).pluck(:account_id)
    end

    def get_all_community_admins
      Mammoth::Account.joins(users: :community_admins)
    end
end