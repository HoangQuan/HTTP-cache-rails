class Crawler < ActiveRecord::Base
  require 'nokogiri'
  require 'open-uri'
  VNEXPRESS_URLS = ["http://vnexpress.net/rss/tin-moi-nhat.rss"]
  SOHA_DANTRI_URLS = ["http://soha.vn/giai-tri.rss", "http://dantri.com.vn/trangchu.rss"]
  THOISU_URL = ["http://vnexpress.net/rss/thoi-su.rss", "http://soha.vn/xa-hoi.rss", "http://dantri.com.vn/xa-hoi.rss"]

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
          crawl_noko url, ""
        end

        SOHA_DANTRI_URLS.each do |url|
          crawl_crack url, ""
        end
      rescue Timeout::Error
        ""
      end
    end

    def crawl_by_action action_name
      case action_name
      when "thoi-su"
        THOISU_URL.each do |url|
          if url.include? "vnexpress"
            crawl_noko url, "thoi-su"
          else
            crawl_crack url, "thoi-su"
          end
        end
      end
    end

    def crawl_noko url, tag
      page = Nokogiri::HTML(open(url))
      items = page.search("item")
      items.each do |item|
        link = item.text.split("\n").find{ |a| a =~ /http:/i}.strip
        if valid_url link
          @post = Post.new title: item.at("title").text,
          description: item.at("description").text,
          image: item.at("img").attributes["src"].value,
          link: link, tag: tag
          @post.save if @post.valid?
        end
      end
    end

    def crawl_crack url, tag
      page = Crack::XML.parse Net::HTTP.get_response(URI(url)).body
      items = page["rss"]["channel"]["item"]
      items.each do |item|
        link = item["link"]
        if valid_url link
          @post = Post.new title: item["title"],
          description: item["title"],
          image: item["description"].split("\"").select{ |a| a =~ /https:/i}.last,
          link: link, tag: tag
          @post.save if @post.valid?
        end
      end
    end

    def get_domain
      uri = URI.parse(link)
      domain = PublicSuffix.parse(uri.host)
      domain.domain
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
