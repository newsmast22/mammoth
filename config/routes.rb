Mammoth::Engine.routes.draw do

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resource :amplifier_settings

      resources :polls, except: [:create, :show] do
        member do
          post :fedi_vote, controller: 'polls/votes'
        end
      end

      resources :tags, except: [:show] do
        member do
          post :fedi_follow
          post :fedi_unfollow
        end
      end

      resources :media, except: [:create, :update, :show] do
        collection do
          post :fedi_create
        end

        member do
          put :fedi_update
          get :fedi_show
        end
      end
      resources :statuses, except: [:create, :show, :update, :destroy] do
        collection do
          post :fedi_create
        end
  
        member do
          get :fedi_show
          patch :fedi_update
          put :fedi_update
          delete :fedi_destroy
        end

        scope module: :statuses do
          resource :fedi_bookmark, only: :create
          post :fedi_unbookmark, to: 'fedi_bookmarks#destroy'

          resource :fedi_pin, only: :create
          post :fedi_unpin, to: 'fedi_pins#destroy' 

          resource :fedi_reblog, only: :create
          post :fedi_unreblog, to: 'fedi_reblogs#destroy'

          resource :fedi_favourite, only: :create
          post :fedi_unfavourite, to: 'fedi_favourites#destroy'
        end
      end

      resources :accounts, except: [:show] do
        collection do 
          get :fedi_tag_commu_count
          patch :fedi_profile_update
        end

        member do
          post :fedi_profile_update
          post :fedi_follow
          post :fedi_unfollow
          post :fedi_remove_from_followers
          post :fedi_block
          post :fedi_unblock
          post :fedi_mute
          post :fedi_unmute
        end
      end

      post 'register_with_email' => 'user_sessions#register_with_email', as: 'register_with_email'
      post 'register_with_phone' => 'user_sessions#register_with_phone', as: 'register_with_phone'
      put  'verify_otp' => 'user_sessions#verify_otp', as: 'verify_otp'
      get  'get_reset_password_otp' => 'user_sessions#get_reset_password_otp', as: 'get_reset_password_otp'
      post 'verify_reset_password_otp' => 'user_sessions#verify_reset_password_otp', as: 'verify_reset_password_otp'
      put  'reset_password' => 'user_sessions#reset_password', as: 'reset_password'
      get 'connect_with_instance' => 'user_sessions#connect_with_instance', as: 'connect_with_instance'
      post 'create_user_object' => 'user_sessions#create_user_object', as: 'create_user_object'

      # for fediverse actions
      post '/fedi_favourite/:status_id', to: 'favourites#favourite', as: 'fedi_favourite'
      post '/fedi_unfavourite/:status_id', to: 'favourites#unfavourite', as: 'fedi_unfavourite'
      post '/fedi_create_status', to: 'statuses#create', as: 'fedi_create_status'
      post '/fedi_delete_status/:status_id', to: 'statuses#delete', as: 'fedi_delete_status'
     
      namespace :community do
        resource :amplifier_setting
      end
      
      resources :communities do
        collection do 
          post 'get_communities_with_collections' => 'communities#get_communities_with_collections', as: 'get_communities_with_collections'
          post 'update_is_country_filter_on' => 'communities#update_is_country_filter_on', as: 'update_is_country_filter_on'
          get 'get_community_follower_list' =>  'communities#get_community_follower_list', as: 'get_community_follower_list'
          get 'get_participants_list' =>  'communities#get_participants_list', as: 'get_participants_list'
          get 'get_admin_following_list' =>  'communities#get_admin_following_list', as: 'get_admin_following_list'
          put 'update_community_bio/:id'=>  'communities#update_community_bio', as: 'update_community_bio'
          get 'people_to_follow/:id'=>  'communities#people_to_follow', as: 'people_to_follow'
          get 'editorial_board/:id'=>  'communities#editorial_board', as: 'editorial_board'
          get 'community_moderators/:id'=>  'communities#community_moderators', as: 'community_moderators'
          get 'bio_hashtags/:id'=>  'communities#bio_hashtags', as: 'bio_hashtags'
        end
        member do
          get :community_bio
        end
      end

      resources :community_feeds

      resource :reblog_statuses, only: :create

      resources :community_admin_settings
      
      resources :community_statuses do
        collection do
          get  'get_community_statues' => 'community_statuses#get_community_statues', as: 'get_community_statues'
          get  'get_my_community_statues' => 'community_statuses#get_my_community_statues', as: 'get_my_community_statues'
          get  'get_community_details_profile' => 'community_statuses#get_community_details_profile', as: 'get_community_details_profile'
          get  'get_community_detail_statues' => 'community_statuses#get_community_detail_statues', as: 'get_community_detail_statues'
          get  'get_recommended_community_detail_statuses' => 'community_statuses#get_recommended_community_detail_statuses', as: 'get_recommended_community_detail_statuses'
          get  'link_preview'  => 'community_statuses#link_preview', as: 'link_preview'
          post  'translate_text'  => 'community_statuses#translate_text', as: 'translate_text'
          post  'translate_mastodon_text'  => 'community_statuses#translate_mastodon_text', as: 'translate_mastodon_text'
        end
        member do
          get :context
        end
      end

      resources :user_communities do
        collection do
          post 'join_unjoin_community' => 'user_communities#join_unjoin_community', as: 'join_unjoin_community'
          post 'join_all_community' => 'user_communities#join_all_community', as: 'join_all_community'
          post 'unjoin_all_community' => 'user_communities#unjoin_all_community', as: 'unjoin_all_community'
          put 'change_primary_community' => 'user_communities#change_primary_community', as: 'change_primary_community'
        end
      end

      resources :collections do
        collection do
          get 'get_collection_by_user' => 'collections#get_collection_by_user', as: 'get_collection_by_user'

          #begin::need to delete
          post 'create_subtitle' => 'collections#create_subtitle', as: 'create_subtitle'
          post 'create_media' => 'collections#create_media', as: 'create_media'
          post 'create_voice' => 'collections#create_voice', as: 'create_voice'
          #end::need to delete
        end
      end

      resources :search do
        collection do
          get 'get_all_community_status_timelines' => 'search#get_all_community_status_timelines', as: 'get_all_community_status_timelines'
          get 'get_my_community_status_timelines' => 'search#get_my_community_status_timelines', as: 'get_my_community_status_timelines'
          post 'create_user_search_setting' => 'search#create_user_search_setting', as: 'create_user_search_setting'
          get 'get_user_search_setting' => 'search#get_user_search_setting', as: 'get_user_search_setting'
        end
      end
      
      resources :primany_timelines

      namespace :timeline do
        get 'all_old', to: 'timelines#all_old'
        get 'all', to: 'timelines#all'
        get 'newsmast', to: 'timelines#newsmast'
        get 'federated', to: 'timelines#federated'
        get 'my_community', to: 'timelines#my_community'
        get 'following', to: 'timelines#following'
      end

      namespace :timeline do
        get 'community_all', to: 'community_timelines#all'
        get 'community_recommended', to: 'community_timelines#recommended'
      end

      
      resources :following_timelines do
        collection do
          get 'get_following_timelines' => 'following_timelines#get_following_timelines', as: 'get_following_timelines'
        end
      end

      resources :tag_timelines do
        collection do
          get 'get_tag_timeline_info' => 'tag_timelines#get_tag_timeline_info', as: 'get_tag_timeline_info'
          get 'get_tag_timline_statuses' => 'tag_timelines#get_tag_timline_statuses', as: 'get_tag_timline_statuses'
        end
      end

      resources :trend_tags do
        collection do
          get 'get_my_community_trend_tag' => 'trend_tags#get_my_community_trend_tag', as: 'get_my_community_trend_tag'
        end
      end
      
      resources :users, only: [] do
        collection do
          put 'change_password'
          put 'change_username'
          put 'change_email_phone'
          put 'deactive_account'
          get 'suggestion'
          get 'global_suggestion'
          patch :update_credentials, to: 'users#update'
          post 'update_account' => 'users#update_account', as: 'update_account'
          post 'update_account_sources' => 'users#update_account_sources', as: 'update_account_sources'
          post 'logout'
          get :show_details, to: 'users#show'
          get 'get_profile_details_by_account' => 'users#get_profile_details_by_account', as: 'get_profile_details_by_account'
          get 'get_country_list' => 'users#get_country_list', as: 'get_country_list'
          get 'get_source_list' => 'users#get_source_list', as: 'get_source_list'
          get 'get_subtitles_list' => 'users#get_subtitles_list', as: 'get_subtitles_list'
          get 'get_profile_detail_info_by_account' => 'users#get_profile_detail_info_by_account', as: 'get_profile_detail_info_by_account'
          get 'get_profile_detail_statuses_by_account' => 'users#get_profile_detail_statuses_by_account', as: 'get_profile_detail_statuses_by_account'
        end
      end
      
      resources :wait_lists do
        collection do
          post 'verify_waitlist' => 'wait_lists#verify_waitlist', as: 'verify_waitlist'
          post 'register_end_user_waitlist' => 'wait_lists#register_end_user_waitlist', as: 'register_end_user_waitlist'
          post 'register_moderator_waitlist' => 'wait_lists#register_moderator_waitlist', as: 'register_moderator_waitlist'
          post 'register_contributor_waitlist' => 'wait_lists#register_contributor_waitlist', as: 'register_contributor_waitlist'
          get  'get_contributor_roles' => 'wait_lists#get_contributor_roles', as: 'get_contributor_roles'
        end
      end

      resources :user_timeline_settings

      resources :user_community_settings

      resources :following_accounts, only: :index

      resources :follower_accounts, only: :index

      resources :following_tags, only: :index

      resources :notification_tokens, only: :create

      resources :mammoth_settings, only: [:index, :create, :destroy]

      resources :app_versions,only: [] do 
        collection do
          post 'check_version' => 'app_versions#check_version', as: 'check_version'
        end
      end

      namespace :community_admin do
        resources :community_filter_keywords do
          member do
            post :unban_statuses
          end
        end
      end

      resources :community_hashtags, only: %i[index]

      resources :drafted_statuses, only: [:create, :index, :show, :update, :destroy] do
        member do
          post :publish
        end
      end

      
    end
  end
end
