class Crawler < ActiveRecord::Base
  require 'nokogiri'
  require 'open-uri'
  VNEXPRESS_URLS = ["http://vnexpress.net/rss/tin-moi-nhat.rss", "http://vnexpress.net/rss/thoi-su.rss"]

  class << self
    def crawl(url)
      begin
        page = Nokogiri::HTML(open(url))
      rescue Timeout::Error
      	"Error"
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

  def chupanh url
    f = Screencap::Fetcher.new(url.to_s)
    screenshot = f.fetch(
      :output => 'public/images/1111.png' # don't forget the extension!
      # optional:
      # :div => '#page', # selector for a specific element to take screenshot of
      # :width => 1024,
      # :height => 768,
      # :top => 0, :left => 0, :width => 100, :height => 100 # dimensions for a specific area
    )
  end

  end
end
