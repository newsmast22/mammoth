module Mammoth::Api::V1
  class UsersController < Api::BaseController
    before_action -> { doorkeeper_authorize! :read }
    before_action :require_user!

    def suggestion
      @user  = Mammoth::User.find(current_user.id)
      @users = Mammoth::User.joins(:user_communities).where.not(id: @user.id).where(user_communities: {community_id: @user.communities.ids}).distinct

      data   = []
      @users.each do |user|
        data << {
          account_id: user.account_id,
          user_id: user.id,
          display_name: user.account.display_name.presence || user.account.username,
          email: user.email
        }
      end
      render json: {data: data}
    end

  end
end