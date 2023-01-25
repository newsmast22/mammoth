Mammoth::Engine.routes.draw do

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      post 'register_with_email' => "user_sessions#register_with_email", as: "register_with_email"
      post 'register_with_phone' => "user_sessions#register_with_phone", as: "register_with_phone"
      put 'verify_otp' => "user_sessions#verify_otp", as: "verify_otp"
      post 'user_sign_in' => "user_sessions#user_sign_in", as: "user_sign_in"

      resources :communities
      resources :community_statuses
      resources :user_communities
      resources :collections
      resources :users, only: [] do
        collection do
          get 'suggestion'
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
