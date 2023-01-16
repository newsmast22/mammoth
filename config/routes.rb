Mammoth::Engine.routes.draw do

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      post 'egister_with_phone' => "user_sessions#register_with_phone", as: "register_with_phone"
      put '/api/v1/verify_otp' => "user_sessions#verify_otp", as: "verify_otp"

      resources :communities
    end
  end
  
end
