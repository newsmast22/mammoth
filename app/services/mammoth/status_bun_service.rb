class Mammoth::StatusBunService < BaseService
  def call(status, options)
    @status = status
    @options = options
    @tags = @status.tags
    @community_ids = @status.communities.pluck(:id)
    @flag = @options[:action] if @options[:action]
    check_and_insert_bun_keyword!
  end

  private

  def check_and_insert_bun_keyword!
    clear_bunned_status_by_id! if update?
    check_keyword_filters
  end

  def create?
    @flag == 'create'
  end

  def update?
    @flag == 'update'
  end

  def check_keyword!(keyword_obj)
    key_word = keyword_obj.keyword
    is_status_banned = keyword_obj.is_filter_hashtag ? check_hashtag_keyword_filter(key_word) : keyword_filter(key_word)
    bun_status_process!(keyword_obj.id) if is_status_banned
  end

  def check_keyword_filters
    check_global_keywork
    check_community_keywork if @community_ids&.count.to_i >= 1
  end

  def check_community_keywork
    load_filter_keywords_for_communities.each { |community_keyword| check_keyword!(community_keyword) }
  end

  def check_global_keywork
    load_filter_keywords_for_communities(nil).each { |global_key_word| check_keyword!(global_key_word) }
  end

  def load_filter_keywords_for_communities(community_id = @community_ids)
    Mammoth::CommunityFilterKeyword.where(community_id: community_id)
                                  .find_in_batches(batch_size: 100, order: :desc)
                                  .flat_map(&:itself)
  end

  def keyword_filter(key_word)
    @status.search_word_ban(key_word.downcase)
  end

  def check_hashtag_keyword_filter(key_word)
    @tags&.where(name: key_word.downcase.gsub("#", "")).exists?
  end

  def bun_status_process!(key_word_id)
    Mammoth::CommunityFilterStatus.find_or_create_by(
      status_id: @status.id,
      community_filter_keyword_id: key_word_id
    )
    DistributionWorker.perform_async(@status.id)
    RemoveStatusService.new.call(Status.with_discarded.find(@status), options = {'immediate' => false})
  end

  def clear_bunned_status_by_id!
    Mammoth::CommunityFilterStatus.where(status_id: @status.id).destroy_all
    DistributionWorker.perform_async(@status.id)
  end
end
