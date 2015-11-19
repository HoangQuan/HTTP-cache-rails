class Post < ActiveRecord::Base
	# https://github.com/pauldix/domainatrix
	validates :link, uniqueness: true
	def get_domain
		uri = URI.parse(link)
		domain = PublicSuffix.parse(uri.host)
		domain.domain
	end
end
