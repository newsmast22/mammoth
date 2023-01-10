NewsmastSsoClient::Engine.routes.draw do

  post '/api/v1/register_with_phone' => "user_sessions#register_with_phone", as: "register_with_phone", :defaults => { :format => 'json' }
  put '/api/v1/verify_otp' => "user_sessions#verify_otp", as: "verify_otp", :defaults => { :format => 'json' }
  
  # post '/users/sign_in' => "user_sessions#create"
  # delete '/users/sign_out' => "user_sessions#destroy", as: "sign_out"
  # get '/users/preferences' => "users#edit", as: "preferences"
  # get '/users/suggest' => "users#suggest", as: "suggest_users"
  # get '/users/check_email' => "users#check_email", as: "check_email"

  # resources :users do
  #   put :set_password, on: :member
  # end

end
