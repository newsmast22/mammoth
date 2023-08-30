module Mammoth::Api::V1
  class TagTimelinesController < Api::BaseController
    before_action :load_tag
    before_action :require_user!
		before_action -> { doorkeeper_authorize! :read , :write}

    def show
      if params[:id].present? && @tag.present?
        query_string = "AND statuses.id < :max_id" if params[:max_id].present?

        @statuses = @tag.statuses.where("
                    statuses.reply = :reply #{query_string}",
                    reply: false,max_id: params[:max_id])

        #@statuses = @tag.statuses.where(reply: false)

        
        #begin::muted account post
        muted_accounts = Mute.where(account_id: current_account.id)
        @statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
        #end::muted account post

        #begin::blocked account post
        blocked_accounts = Block.where(account_id: current_account.id).or(Block.where(target_account_id: current_account.id))
        unless blocked_accounts.blank?

          combined_block_account_ids = blocked_accounts.pluck(:account_id,:target_account_id).flatten
          combined_block_account_ids.delete(current_account.id)

          blocked_statuses_by_accounts= Mammoth::Status.where(account_id: combined_block_account_ids)
          blocled_status_ids = @statuses.fetch_all_blocked_status_ids(blocked_statuses_by_accounts.pluck(:id).map(&:to_i))
          @statuses = @statuses.filter_blocked_statuses(blocled_status_ids.pluck(:id).map(&:to_i))
      
        end
        #end::blocked account post

        #begin::deactivated account post
        deactivated_accounts = Account.joins(:user).where('users.is_active = ?', false)
        unless deactivated_accounts.blank?
          deactivated_statuses = @statuses.blocked_account_status_ids(deactivated_accounts.pluck(:id).map(&:to_i))
          deactivated_reblog_statuses =  @statuses.blocked_reblog_status_ids(deactivated_statuses.pluck(:id).map(&:to_i))
          deactivated_statuses_ids = get_integer_array_from_list(deactivated_statuses)
          deactivated_reblog_statuses_ids = get_integer_array_from_list(deactivated_reblog_statuses)
          combine_deactivated_status_ids = deactivated_statuses_ids + deactivated_reblog_statuses_ids
          @statuses = @statuses.filter_blocked_statuses(combine_deactivated_status_ids)
        end
        #end::deactivated account post

        tag = Tag.find_normalized(params[:id]) || Tag.new(name: Tag.normalize(params[:id]), display_name: params[:id])
        tagFollow = TagFollow.where(tag_id: tag.id)
        unless @statuses.empty?
          #begin::muted account post
          muted_accounts = Mute.where(account_id: current_account.id)
          @statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?

          before_limit_statuses = @statuses
          @statuses = @statuses.order(created_at: :desc).limit(5)
          render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer,current_user: current_user, adapter: :json, 
          meta: { 
            tag_name: tag.display_name,
            following: tagFollow.pluck(:account_id).map(&:to_i).include?(current_account.id),
            post_count: Mammoth::StatusTag.where(tag_id: tag.id).count,
            following_count: tagFollow.count,
            pagination:
              { 
                total_objects: nil,
                has_more_objects: 5 <= before_limit_statuses.size ? true : false
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
                  total_objects: 0,
                  has_more_objects: false
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
              total_objects: 0,
              has_more_objects: false
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
        #@statuses = @tag.statuses.where(reply: false)
        query_string = "AND statuses.id < :max_id" if params[:max_id].present?

        @statuses = @tag.statuses.where("
                    statuses.reply = :reply #{query_string}",
                    reply: false,max_id: params[:max_id])
        unless @statuses.empty?

          #begin::muted account post
          muted_accounts = Mute.where(account_id: current_account.id)
          @statuses = @statuses.filter_mute_accounts(muted_accounts.pluck(:target_account_id).map(&:to_i)) unless muted_accounts.blank?
          #end::muted account post

          #begin::blocked account post
          blocked_accounts = Block.where(account_id: current_account.id).or(Block.where(target_account_id: current_account.id))
          unless blocked_accounts.blank?

            combined_block_account_ids = blocked_accounts.pluck(:account_id,:target_account_id).flatten
            combined_block_account_ids.delete(current_account.id)

            blocked_statuses_by_accounts= Mammoth::Status.where(account_id: combined_block_account_ids)
            blocled_status_ids = @statuses.fetch_all_blocked_status_ids(blocked_statuses_by_accounts.pluck(:id).map(&:to_i))
            @statuses = @statuses.filter_blocked_statuses(blocled_status_ids.pluck(:id).map(&:to_i))
          
          end
          #end::blocked account post

          #begin::deactivated account post
          deactivated_accounts = Account.joins(:user).where('users.is_active = ?', false)
          unless deactivated_accounts.blank?
            deactivated_statuses = @statuses.blocked_account_status_ids(deactivated_accounts.pluck(:id).map(&:to_i))
            deactivated_reblog_statuses =  @statuses.blocked_reblog_status_ids(deactivated_statuses.pluck(:id).map(&:to_i))
            deactivated_statuses_ids = get_integer_array_from_list(deactivated_statuses)
            deactivated_reblog_statuses_ids = get_integer_array_from_list(deactivated_reblog_statuses)
            combine_deactivated_status_ids = deactivated_statuses_ids + deactivated_reblog_statuses_ids
            @statuses = @statuses.filter_blocked_statuses(combine_deactivated_status_ids)
          end
          #end::deactivated account post

          # @statuses = @statuses.order(created_at: :desc).page(params[:page]).per(5)
          # render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer,current_user: current_user, adapter: :json, 
          # meta: { 
          #   pagination:
          #     { 
          #       total_pages: @statuses.total_pages,
          #       total_objects: @statuses.total_count,
          #       current_page: @statuses.current_page
          #     } 
          #   }

          before_limit_statuses = @statuses
          @statuses = @statuses.order(created_at: :desc).limit(5)
          render json: @statuses,root: 'data', each_serializer: Mammoth::StatusSerializer,current_user: current_user, adapter: :json, 
          meta: { 
            pagination:
              { 
                total_objects: before_limit_statuses.size,
                has_more_objects: 5 <= before_limit_statuses.size ? true : false
              } 
            }
        else
          render json: { 
            data: [],
            meta: { 
              pagination:
                { 
                  total_objects: 0,
                  has_more_objects: false
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
                  total_objects: 0,
                  has_more_objects: false
                } 
              }
            }
      end   
    end

    private

    def load_tag
      @tag = Mammoth::Tag.find_normalized(params[:id])
    end

    def get_integer_array_from_list(obj_list)
      if obj_list.blank?
       return []
      else
        return obj_list.pluck(:id).map(&:to_i)
      end
    end
  end
end