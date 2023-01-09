module NewsmastSsoClient
  class UserSessionsController < ApplicationController
    # include DroomAuthentication
    # before_action :require_no_user!, only: [:new, :create]
    # before_action :authenticate_user!, only: [:destroy]

    def new
      
    end

    def test
      render json: {message: 'Hello world!'}
    end

  end
end
