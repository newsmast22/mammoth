class Mammoth::UserCommunitiesService < BaseService
  def initialize(params,current_user)
    @params = params
    @current_user = current_user
    @params.permit!
    if @params.include?(:is_virtual)
      @is_virtual = @params[:is_virtual]
    elsif @params.include?(:community_slug)
      @is_virtual = false
    else
      @is_virtual = false
    end 
  end

  def get_user_communities
    @user = Mammoth::User.find(@current_user.id)
    @communities = @user&.communities || []
    @user_communitiess = Mammoth::UserCommunity.where(user_id: @current_user.id)
    @user_communities = Mammoth::UserCommunity.find_by(user_id: @current_user.id,is_primary: true)
    @data = []
    
    unless @communities.empty?
      @communities.each do |community|
        @data << {
          id: community.id.to_s,
          user_id: @user.id.to_s,
          is_primary: community.id == (@user_communities&.community_id || 0) ? true : false,
          name: community.name,
          slug: community.slug,
          image_file_name: community.image_file_name,
          image_content_type: community.image_content_type,
          image_file_size: community.image_file_size,
          image_updated_at: community.image_updated_at,
          description: community.description,
          image_url: community.image.url,
          collection_id: community.collection.id,
          followers: Mammoth::UserCommunity.where(community_id: community.id).size,
          created_at: community.created_at,
          updated_at: community.updated_at,
          is_default_checked: false,
          community_hashtags: get_community_hashtags(community.id)
        }
      end

      @data = @data.sort_by {|h| [h[:is_primary] ? 0 : 1,h[:slug]]}

      if @params[:community_slug].present? && !(@params[:community_slug] == ENV['ALL_COLLECTION'] || @params[:community_slug] == ENV['NEWSMAST_COLLECTION'])
        new_community = Mammoth::Community.find_by(slug: @params[:community_slug])
        unless @data.any? { |obj| obj[:slug] == @params[:community_slug] }
          @data.prepend << {
            id: new_community.id.to_s,
            user_id: @user.id.to_s,
            is_primary:  false,
            name: new_community.name,
            slug: new_community.slug,
            image_file_name: new_community.image_file_name,
            image_content_type: new_community.image_content_type,
            image_file_size: new_community.image_file_size,
            image_updated_at: new_community.image_updated_at,
            description: new_community.description,
            image_url: new_community.image.url,
            collection_id: new_community.collection.id,
            followers: Mammoth::UserCommunity.where(community_id: new_community.id).size,
            created_at: new_community.created_at,
            updated_at: new_community.updated_at,
            is_default_checked: false,
            community_hashtags: get_community_hashtags(new_community.id)
          }
          @data = @data.sort_by {|h| [h[:slug] == new_community.slug ? 0 : 1,h[:slug]]}
        end
      end
      
      virtual_community

      if @params.include?(:status_id)
        fetch_status_communities(@params[:status_id])
      end

    end
    return @data
    #return @user_communitiess
  end

  def fetch_status_communities(status_id)

    status = Status.where(id: status_id).last
    
    if status.present?
      status_communities = status.communities

      # Loop status's communities [start]
      status_communities.each do |status_community|
        id_to_update = status_community.id.to_s

        # Check status communities within user's communities,
        # If found then update is_default_checked to true
        # Loop user's communities [start]
        @data.each do |item|
          if item[:id] == id_to_update
            item[:is_default_checked] = true
            break  # Exit the loop once the update is done
          end
        end
        # Loop user's communities [end]

        # Check status communities exist in user's communities,
        # If not include then append to exciting array and is_default_checked to true
        unless @data.any? { |obj| obj[:slug] == status_community.slug }
          @data.append << {
            id: status_community.id.to_s,
            user_id: @user.id.to_s,
            is_primary:  false,
            name: status_community.name,
            slug: status_community.slug,
            image_file_name: status_community.image_file_name,
            image_content_type: status_community.image_content_type,
            image_file_size: status_community.image_file_size,
            image_updated_at: status_community.image_updated_at,
            description: status_community.description,
            image_url: status_community.image.url,
            collection_id: status_community.collection.id,
            followers: Mammoth::UserCommunity.where(community_id: status_community.id).size,
            created_at: status_community.created_at,
            updated_at: status_community.updated_at,
            is_default_checked: true,
            community_hashtags: get_community_hashtags(status_community.id)
          }
        end

      end
      # Loop status's communities [end]

      @data = @data.sort_by {|h| [h[:is_primary] ? 0 : 1,h[:slug]]}
      
    end
  end

  def self.virtual_user_community_details
    { 
      community_followed_user_counts: 0,
      community_name: ENV['NEWSMAST_COLLECTION'].capitalize,
      community_description:  "All posts from the communities of Newsmast.",
      collection_name: ENV['NEWSMAST_COLLECTION'].capitalize,
      community_url: "https://newsmast-assets.s3.eu-west-2.amazonaws.com/my_server_newsmast_cover_photos/newsmast_community_profile_photo.png",
      community_header_url: "https://newsmast-assets.s3.eu-west-2.amazonaws.com/my_server_newsmast_cover_photos/newsmast_community_cover_photo.png",
      community_slug: ENV['NEWSMAST_COLLECTION'],
      is_joined: false,
      is_admin: false,
      is_virtual: true
    }
  end

  def virtual_community
    if @is_virtual == 'true' || @is_virtual.nil?
      @data.unshift( {
        id: @communities.count  + 1,
        user_id: @user.id.to_s,
        is_primary: false,
        is_virtual: true,
        name: ENV['NEWSMAST_COLLECTION'].capitalize,
        slug: ENV['NEWSMAST_COLLECTION'],
        image_file_name: ENV['NEWSMAST_COLLECTION'],
        image_content_type: nil,
        image_file_size: nil,
        image_updated_at: Time.now,
        description: "All posts from the communities of Newsmast.",
        image_url: "https://newsmast-assets.s3.eu-west-2.amazonaws.com/my_server_newsmast_cover_photos/newsmast_community_profile_photo.png",
        collection_id: nil,
        followers: 0,
        created_at: Time.now,
        updated_at: Time.now,
        is_default_checked: false
      } )
    end
  end

  private

  def get_community_hashtags(community_id)
    Mammoth::CommunityHashtag.where(community_id: community_id, is_incoming: false).pluck(:hashtag).map{|a| "##{a}" }
  end

end