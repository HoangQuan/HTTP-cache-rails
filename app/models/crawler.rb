class Crawler < ActiveRecord::Base
  require 'nokogiri'
  require 'open-uri'
  VNEXPRESS_URLS = ["http://vnexpress.net/rss/tin-moi-nhat.rss", "http://vnexpress.net/rss/thoi-su.rss"]

  class << self
    def crawl(url)
      begin
        page = Nokogiri::HTML(open(url))
      rescue Timeout::Error
      	""
      end
    end
    def crawl_barch
      begin
        VNEXPRESS_URLS.each do |url|
          page = Nokogiri::HTML(open(url))
          items = page.search("item")
          items.each do |item|
            link = item.text.split("\n").find{ |a| a =~ /http:/i}.strip
            if valid_url link
              Post.create title: item.at("title").text,
              description: item.at("description").text,
              image: item.at("img").attributes["src"].value,
              link: link
            end
          end
        end
      rescue Timeout::Error
        ""
      end
    end

    def valid_url url
      res = Net::HTTP.get_response URI(url)
      res.body.present?
    end
  end
end
