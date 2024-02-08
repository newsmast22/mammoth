class Mammoth::FilterKeywordCreateService < BaseService
  def call(current_account, keyword, options)
    @current_account = current_account
    @keyword = keyword 
    @options = options
    @flag = @options[:action] if @options[:action]
    create_keyword_process!
  end

  private

  def create_keyword_process!
    clear_old_keyword! if update?
    create_keyword! if create?
  end

  def clear_old_keyword!
    
  end

  def create?
    @flag == 'create'
  end

  def update?
    @flag == 'update'
  end
end