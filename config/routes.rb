Mammoth::Engine.routes.draw do

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      post 'register_with_phone' => "user_sessions#register_with_phone", as: "register_with_phone"
      put 'verify_otp' => "user_sessions#verify_otp", as: "verify_otp"
      post 'create_statues_with_communities' => "statues_with_communities#create_statues_with_communities", as: "create_statues_with_communities"
      resources :communities
    end
  end
  
end
