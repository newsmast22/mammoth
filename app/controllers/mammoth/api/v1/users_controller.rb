module Mammoth::Api::V1
  class UsersController < Api::BaseController
    before_action -> { doorkeeper_authorize! :read }
    before_action :require_user!

    def suggestion
      @user  = Mammoth::User.find(current_user.id)
      @users = Mammoth::User.joins(:user_communities).where.not(id: @user.id).where(user_communities: {community_id: @user.communities.ids}).distinct
      render json: {data: @users}
    end

  end
end