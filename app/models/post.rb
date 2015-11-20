class Post < ActiveRecord::Base
	# https://github.com/pauldix/domainatrix
	validates :link, uniqueness: true
	scope :order_by_created_at, ->{order("created_at DESC")}
	def get_domain
		uri = URI.parse(link)
		domain = PublicSuffix.parse(uri.host)
		domain.domain
	end
end
