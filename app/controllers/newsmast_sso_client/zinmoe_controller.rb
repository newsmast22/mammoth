module NewsmastSsoClient
	class ZinmoeController < ApplicationController

		def testing
			render json: {message: "Hello world!"}
		end
	end		
end