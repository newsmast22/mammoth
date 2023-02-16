Mammoth::Engine.routes.draw do

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      post 'register_with_email' => "user_sessions#register_with_email", as: "register_with_email"
      post 'register_with_phone' => "user_sessions#register_with_phone", as: "register_with_phone"
      put  'verify_otp' => "user_sessions#verify_otp", as: "verify_otp"
      get  'get_reset_password_otp' => 'user_sessions#get_reset_password_otp', as: 'get_reset_password_otp'
      post 'verify_reset_password_otp' => 'user_sessions#verify_reset_password_otp', as: 'verify_reset_password_otp'
      put  'reset_password' => 'user_sessions#reset_password', as: 'reset_password'
      get  'search' => 'search#index', as: 'search'

      resources :communities

      resources :community_statuses do
        collection do
          get  'get_community_statues' => 'community_statuses#get_community_statues', as: 'get_community_statues'
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
        end
      end
      
      resources :primany_timelines
      resources :following_timelines
      resources :tag_timelines
      resources :trend_tags
      resources :users, only: [] do
        collection do
          get 'suggestion'
          patch :update_credentials, to: 'users#update'
          post 'logout'
          get :show_details, to: 'users#show'
          get  'get_profile_details_by_account' => "users#get_profile_details_by_account", as: "get_profile_details_by_account"
          get  'get_country_list' => "users#get_country_list", as: "get_country_list"
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

    end
  end
end