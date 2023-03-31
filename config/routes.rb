Mammoth::Engine.routes.draw do

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      post 'register_with_email' => "user_sessions#register_with_email", as: "register_with_email"
      post 'register_with_phone' => "user_sessions#register_with_phone", as: "register_with_phone"
      put  'verify_otp' => "user_sessions#verify_otp", as: "verify_otp"
      get  'get_reset_password_otp' => 'user_sessions#get_reset_password_otp', as: 'get_reset_password_otp'
      post 'verify_reset_password_otp' => 'user_sessions#verify_reset_password_otp', as: 'verify_reset_password_otp'
      put  'reset_password' => 'user_sessions#reset_password', as: 'reset_password'
      get  'search_all_commnities' => 'search_all_commnities#index', as: 'search_all_commnities'
      get  'search_my_communities' => 'search_my_communities#index', as: 'search_my_communities'

      resources :communities do 
        collection do 
          get  'communitiesWithCollection' => 'communities#communitiesWithCollection', as: 'communitiesWithCollection'
          post  'update_is_country_filter_on' => 'communities#update_is_country_filter_on', as: 'update_is_country_filter_on'
        end
      end

      resources :community_feeds

      resource :reblog_statuses, only: :create

      resources :community_admin_settings
      
      resources :community_statuses do
        collection do
          get  'get_community_statues' => 'community_statuses#get_community_statues', as: 'get_community_statues'
          get  'get_my_community_statues' => 'community_statuses#get_my_community_statues', as: 'get_my_community_statues'
        end
        member do
          get :context
        end
      end

      resources :user_communities do
        collection do
          post  'join_unjoin_community' => "user_communities#join_unjoin_community", as: "join_unjoin_community"
        end
      end

      resources :collections do
        collection do
          get 'get_collection_by_user' => "collections#get_collection_by_user", as: "get_collection_by_user"

          #begin::need to delete
          post 'create_subtitle' => "collections#create_subtitle", as: "create_subtitle"
          post 'create_media' => "collections#create_media", as: "create_media"
          post 'create_voice' => "collections#create_voice", as: "create_voice"
          #end::need to delete
        end
      end

      resources :search do
        collection do
          get 'get_all_community_status_timelines' => "search#get_all_community_status_timelines", as: "get_all_community_status_timelines"
          get 'get_my_community_status_timelines' => "search#get_my_community_status_timelines", as: "get_my_community_status_timelines"
          post 'create_user_search_setting' => "search#create_user_search_setting", as: "create_user_search_setting"
          get 'get_user_search_setting' => "search#get_user_search_setting", as: "get_user_search_setting"

        end
      end
      
      resources :primany_timelines
      resources :following_timelines
      resources :tag_timelines

      resources :trend_tags do
        collection do
          get 'get_my_community_trend_tag' => 'trend_tags#get_my_community_trend_tag', as: "get_my_community_trend_tag"
        end
      end
      
      resources :users, only: [] do
        collection do
          get 'suggestion'
          get 'global_suggestion'
          patch :update_credentials, to: 'users#update'
          post 'update_account' => "users#update_account", as: "update_account"
          post 'update_account_sources' => "users#update_account_sources", as: "update_account_sources"
          post 'logout'
          get :show_details, to: 'users#show'
          get 'get_profile_details_by_account' => "users#get_profile_details_by_account", as: "get_profile_details_by_account"
          get 'get_country_list' => "users#get_country_list", as: "get_country_list"
          get 'get_source_list' => "users#get_source_list", as: "get_source_list"
          get 'get_subtitles_list' => "users#get_subtitles_list", as: "get_subtitles_list"
        end
      end
      
      resources :wait_lists do
        collection do
          post 'verify_waitlist' => "wait_lists#verify_waitlist", as: "verify_waitlist"
          post 'register_end_user_waitlist' => "wait_lists#register_end_user_waitlist", as: "register_end_user_waitlist"
          post 'register_moderator_waitlist' => "wait_lists#register_moderator_waitlist", as: "register_moderator_waitlist"
          post 'register_contributor_waitlist' => "wait_lists#register_contributor_waitlist", as: "register_contributor_waitlist"
          get  'get_contributor_roles' => "wait_lists#get_contributor_roles", as: "get_contributor_roles"
        end
      end

      resources :user_timeline_settings

      resources :following_accounts, only: :index

    end
  end
end