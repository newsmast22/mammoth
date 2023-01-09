NewsmastSsoClient::Engine.routes.draw do

  get '/zinmoe/testing' => "zinmoe#testing"

  get '/users/sign_in' => "user_sessions#new", as: "sign_in"
  get '/users/test' => "user_sessions#test"
  # post '/users/sign_in' => "user_sessions#create"
  # delete '/users/sign_out' => "user_sessions#destroy", as: "sign_out"
  # get '/users/preferences' => "users#edit", as: "preferences"
  # get '/users/suggest' => "users#suggest", as: "suggest_users"
  # get '/users/check_email' => "users#check_email", as: "check_email"

  # resources :users do
  #   put :set_password, on: :member
  # end

end
