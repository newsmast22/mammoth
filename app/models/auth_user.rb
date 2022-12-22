class AuthUser < ActiveResource::Base
	self.site = "https://newsmast.croucher.org"
	self.include_format_in_path = false
	self.headers['Authorization'] = 'Token token="ItZgZwfcKvADEXGR5eiNX_KhaVCqkBsZU19xqJf9HLo"'
	def get_users
		User.all
	end
end