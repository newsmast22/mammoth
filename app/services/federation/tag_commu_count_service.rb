class Federation::TagCommuCountService < BaseService
  def call(current_user)
    @current_user = current_user 
    hash_tag_count!
    community_count!
    result_set!
  end

  private

  def result_set!
    { 
      tag_count: @tag_count,
      community_count: @community_count
    }
  end

  def hash_tag_count!
    @tag_count = @current_user.tags.count
  end

  def community_count!
    @community_count = Mammoth::UserCommunity.where(user_id: @current_user.user.id).count
  end
end