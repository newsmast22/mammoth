module Mammoth::Api::V1
  class TagTimelinesController < Api::BaseController
    before_action :load_tag
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def show
      if params[:id].present?
        @statuses = @tag.statuses.where(reply: false)
        
        #begin::muted account post
        muted_accounts = Mute.where(account_id: current_account.id)
        @statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
        #end::muted account post

        #begin::blocked account post
        blocked_accounts = Block.where(account_id: current_account.id).or(Block.where(target_account_id: current_account.id))
        unless blocked_accounts.blank?
          combined_block_account_ids = blocked_accounts.pluck(:account_id,:target_account_id).flatten
          combined_block_account_ids.delete(current_account.id)
          unblocked_status_ids = Mammoth::Status.new.reblog_posts(4_096, combined_block_account_ids, nil)
          @statuses = @statuses.filter_with_community_status_ids(unblocked_status_ids)
        end
        #end::blocked account post

        tag = Tag.find_normalized(params[:id]) || Tag.new(name: Tag.normalize(params[:id]), display_name: params[:id])
        tagFollow = TagFollow.where(tag_id: tag.id)
        unless @statuses.empty?
          #begin::muted account post
          muted_accounts = Mute.where(account_id: current_account.id)
          @statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
          #end::muted account post
          @statuses = @statuses.order(created_at: :desc).page(params[:page]).per(10)
          render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, adapter: :json, 
          meta: { 
            tag_name: tag.display_name,
            following: tagFollow.pluck(:account_id).map(&:to_i).include?(current_account.id),
            post_count: Mammoth::StatusTag.where(tag_id: tag.id).count,
            following_count: tagFollow.count,
            pagination:
              { 
                total_pages: @statuses.total_pages,
                total_objects: @statuses.total_count,
                current_page: @statuses.current_page
              } 
            }
        else
          render json: { data: [],
            meta: { 
              tag_name: tag.display_name,
              following: tagFollow.pluck(:account_id).map(&:to_i).include?(current_account.id),
              post_count: Mammoth::StatusTag.where(tag_id: tag.id).count,
              following_count: tagFollow.count,
              pagination:
                { 
                  total_pages: 0,
                  total_objects: 0,
                  current_page: 0
                } 
              }
            }
        end 
      else
        render json: {
          data: [],
          meta: {
            tag_name: "",
            following: "",
            post_count: 0,
            following_count: 0,
            pagination:
            { 
              total_pages: 0,
              total_objects: 0,
              current_page: 0
            } 
          }
        }
      end      
    end

    def get_tag_timeline_info
      if params[:id].present?
        tag = Tag.find_normalized(params[:id]) || Tag.new(name: Tag.normalize(params[:id]), display_name: params[:id])
        tagFollow = TagFollow.where(tag_id: tag.id)
          render json: {
          data: { 
            tag_name: tag.display_name,
            following: tagFollow.pluck(:account_id).map(&:to_i).include?(current_account.id),
            post_count: Mammoth::StatusTag.where(tag_id: tag.id).count,
            following_count: tagFollow.count
            }
          }
      else
        render json: {
          error: "Record not found"
         }
      end   
    end

    def get_tag_timline_statuses
      if params[:id].present?
        @statuses = @tag.statuses.where(reply: false)
        unless @statuses.empty?

          #begin::muted account post
          muted_accounts = Mute.where(account_id: current_account.id)
          @statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
          #end::muted account post

          @statuses = @statuses.order(created_at: :desc).page(params[:page]).per(10)
          render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer, adapter: :json, 
          meta: { 
            pagination:
              { 
                total_pages: @statuses.total_pages,
                total_objects: @statuses.total_count,
                current_page: @statuses.current_page
              } 
            }
        else
          render json: { 
            data: [],
            meta: { 
              pagination:
                { 
                  total_pages: 0,
                  total_objects: 0,
                  current_page: 0
                } 
              }
            }
        end 
      else
        render json: {
          data: [],
            meta: { 
              pagination:
                { 
                  total_pages: 0,
                  total_objects: 0,
                  current_page: 0
                } 
              }
            }
      end   
    end

    private

    def load_tag
      @tag = Mammoth::Tag.find_normalized(params[:id])
    end
  end
end