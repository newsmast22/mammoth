Mammoth::Engine.routes.draw do

  post '/api/v1/register_with_phone' => "user_sessions#register_with_phone", as: "register_with_phone", :defaults => { :format => 'json' }
  put '/api/v1/verify_otp' => "user_sessions#verify_otp", as: "verify_otp", :defaults => { :format => 'json' }
  
end
