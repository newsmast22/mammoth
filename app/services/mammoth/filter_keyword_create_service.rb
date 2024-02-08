class Mammoth::FilterKeywordCreateService < BaseService
  def call(current_account, keyword_obj, options)
    @current_account = current_account
    @keyword_obj = keyword_obj
    @options = options
    @flag = @options[:action] if @options[:action]
    create_keyword_process!
  end

  private

  def create_keyword_process!
    clear_old_keyword! if update?
    create_keyword_regenate!
  end

  def create_keyword_regenate!
    if @keyword_obj.is_filter_hashtag
      create_hashtag_keyword_regenate
    else
      create_regular_keyword_regenate
    end
  end

  def create_hashtag_keyword_regenate
    keyword = @keyword_obj.keyword.downcase
    tag = Tag.find_by(name: keyword.gsub('#', ''))
    ban_statuses(tag.statuses) if tag
  end

  def create_regular_keyword_regenate
    status_list = Mammoth::Status.order(created_at: :desc).limit(400)
    status_list.each do |status|
      ban_statuses([status]) if status.search_word_ban(@keyword_obj.keyword)
    end
  end

  def ban_statuses(statuses = [])
    community_filter_statuses = statuses.map { |status| { status_id: status.id, community_filter_keyword_id: @keyword_obj.id } }
    Mammoth::CommunityFilterStatus.create(community_filter_statuses)

    statuses.each do |status|
      DistributionWorker.perform_async(status.id)
    end
  end

  def clear_old_keyword!
    Mammoth::CommunityFilterStatus.where(community_filter_keyword_id: @keyword_obj.id).destroy_all
  end

  def create?
    @flag == 'create'
  end

  def update?
    @flag == 'update'
  end
end
