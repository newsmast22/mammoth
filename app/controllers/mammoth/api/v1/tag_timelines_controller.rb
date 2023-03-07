module Mammoth::Api::V1
  class TagTimelinesController < Api::BaseController
    before_action :load_tag
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def show
      if params[:id].present?
        @statuses = @tag.statuses.where(reply: false).order(created_at: :desc).take(10)
        tag = Tag.find_normalized(params[:id]) || Tag.new(name: Tag.normalize(params[:id]), display_name: params[:id])
        tagFollow = TagFollow.where(tag_id: tag.id)
        unless @statuses.empty?
          render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, adapter: :json, 
          meta: { 
            tag_name: tag.display_name,
            following: tagFollow.pluck(:account_id).map(&:to_i).include?(current_account.id),
            post_count: Mammoth::StatusTag.where(tag_id: tag.id).count,
            following_count: tagFollow.count,
            }
        else
          render json: { data: [],
            meta: { 
              tag_name: tag.display_name,
              following: tagFollow.pluck(:account_id).map(&:to_i).include?(current_account.id),
              post_count: Mammoth::StatusTag.where(tag_id: tag.id).count,
              following_count: tagFollow.count,
              }
            }
        end 
      else
        render json: {
          error: "Record not found"
         }
      end      
    end

    # require 'rss'
    # require 'open-uri'
    # def rss 
    #   rss_results = []
    #   url = 'https://rss.app/feeds/E6fryGxw2Vo0OPyU.xml'
    #   URI.open(url) do |rss|
    #     feed = RSS::Parser.parse(rss)
    #     puts '----------------------------------------'
    #     puts feed
    #     puts '-----------------------------------------'
    #     puts "Title: #{feed.channel.title}"
    #     feed.items.each do |item|
    #       puts "Item: #{item.title}"
    #     end

    #     feed.items.each do |result|
    #       result = { title: result.title, date: result.pubDate, link: result.link, description: result.description }
    #       rss_results.push(result)
    #     end

    #     render json: rss_results
    #   end
    # end

    private

    def load_tag
      @tag = Tag.find_normalized(params[:id])
    end
  end
end