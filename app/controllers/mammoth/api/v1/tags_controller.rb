# frozen_string_literal: true

class Mammoth::Api::V1::TagsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :follow, :write, :'write:follows' }, except: :show
  before_action :require_user!, except: :show
  before_action :set_or_create_tag

  override_rate_limit_headers :follow, family: :follows

  def show
    cache_if_unauthenticated!
    render json: @tag, serializer: REST::TagSerializer
  end

  def fedi_follow
    response = perform_action('follow')
    render json: response
  end

  def fedi_unfollow
    response = perform_action('unfollow')
    render json: response
  end

  private

  def perform_action(activity_type)
    Federation::TagService.new.call(
      @tag,
      current_account,
      activity_type: activity_type,
      doorkeeper_token: doorkeeper_token
    )
  end

  def set_or_create_tag
    return not_found unless Tag::HASHTAG_NAME_RE.match?(params[:id])
    @tag = Tag.find_normalized(params[:id]) || Tag.new(name: Tag.normalize(params[:id]), display_name: params[:id])
  end
end
