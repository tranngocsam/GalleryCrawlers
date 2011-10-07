require 'rubygems'
require 'mechanize'
require "./utils"

class Adelson
  def initialize
    @a = Mechanize.new { |agent|
      agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; es-ES; rv:1.9.2.3) Gecko/20100401 Firefox/6.0.2'
    }
  end

  def find_gallery
    @a.get('http://www.adelsongalleries.com/about/') do |page|
      tmp = page.search("#rightcolumn .right p").inner_text.strip.split("\n")
      address = {:title => "Adelson Galleries",
                 :address1 => tmp[0].strip,
                 :city => tmp[1].split(",").first.strip,
                 :state => tmp[1].split(",").last.strip.split(" ").first.strip,
                 :zipcode => tmp[1].split(",").last.strip.split(" ").last.strip
      }
      address[:full] = address[:address1] + ", " + address[:city] + ", " + address[:state] + " " + address[:zipcode]
      address[:phone] = tmp[2].strip
      address[:map] = "http://maps.google.com/?q=#{address[:title] + ", " + address[:full]}"
      address[:web_url] = "http://www.adelsongalleries.com"
      address[:long_description] = page.search("#rightcolumn .left p").inner_text.strip
      address[:working_hours_monday_start_time] = "9:30am"
      address[:working_hours_monday_end_time] = "5:30pm"
      address[:working_hours_tuesday_start_time] = "9:30am"
      address[:working_hours_tuesday_end_time] = "5:30pm"
      address[:working_hours_wednesday_start_time] = "9:30am"
      address[:working_hours_wednesday_end_time] = "5:30pm"
      address[:working_hours_thursday_start_time] = "9:30am"
      address[:working_hours_thursday_end_time] = "5:30pm"
      address[:working_hours_friday_start_time] = "9:30am"
      address[:working_hours_friday_end_time] = "2:00pm"

      return address
    end
  end

  def find_exhibitions
    exhibitions = []
    url = "http://www.adelsongalleries.com/current-exhibitions"
    @a.get(url) do |page|
      page.search("#rightcolumn .exhib a").each do |element|
        link = Utils.get_full_url(element[:href], url)
        exhibition = find_exhibition(link)
        exhibitions << exhibition
      end
    end
    exhibitions << find_upcoming_exhibitions

    return exhibitions
  end

  def find_artists
    artists = []
    url = "http://www.adelsongalleries.com/artists/"
    @a.get(url) do |page|
      page.search("#artists-list .artist-col span").each do |element|
        artist = {}
        artist[:name] = element.inner_text.strip
        artists << artist
      end
      page.search("#artists-list .artist-col a").each do |element|
        link = Utils.get_full_url(element[:href], url)
        artists << find_artist(link)
      end
    end

    return artists
  end

  protected

  def find_artist(href)
    @a.get(href) do |page|
      works = []
      page.search("#rightcolumn #slideshow .slide").each do |element|
        work = {}
        work[:image_url] = element.search("img").first[:src]
        work[:short_description] = element.search("img").first[:alt].strip
        tmp = element.search("div").first.inner_text.split("\n").last.strip rescue nil
        
        unless tmp.nil?
          tmp = tmp.split(/[\s]+/)
          work[:unit] = tmp.last
          work[:width] = tmp.first
          work[:height] = tmp[2]
        end
        
        works << work
      end
      
      artist = {}
      artist[:name] = page.search("#leftcolumn h1").first.inner_text.strip
      artist[:works] = works
      link = Utils.get_full_url(page.search("#leftcolumn a:contains('Biography')").first[:href], href) rescue nil
      artist[:biography] = find_biography(link) unless link.nil?

      return artist
    end
  end

  def find_exhibition(url)
    exhibition = {}
    @a.get(url) do |page|
      exhibition[:title] = page.search("#leftcolumn h1").first.inner_text.strip
      exhibition[:short_desc] = page.search("#leftcolumn h2").first.inner_text.strip rescue nil
      tmp = page.search("#exhib_daterange").first.inner_text.strip
      exhibition[:start_date] = tmp.split("-").first.strip
      exhibition[:end_date] = tmp.split("-").last.strip
    end

    return exhibition
  end

  def find_upcoming_exhibitions
    exhibitions = []
    url = "http://www.adelsongalleries.com/upcoming-exhibitions"
    @a.get(url) do |page|
      page.search("#rightcolumn .exhib a").each do |element|
        link = Utils.get_full_url(element[:href], url)
        exhibition = find_exhibition(link)
        exhibitions << exhibition
      end
    end
    return exhibitions
  end

  def find_biography(url)
    @a.get(url) do |page|
      return page.search("#rightcolumn p").first.inner_text.strip
    end
  end
end

