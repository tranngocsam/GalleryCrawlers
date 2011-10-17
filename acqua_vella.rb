require 'rubygems'
require 'mechanize'
require "cgi"
require "./utils"

class AcquaVella
  def initialize
    @a = Mechanize.new { |agent|
      agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; es-ES; rv:1.9.2.3) Gecko/20100401 Firefox/6.0.2'
    }
  end

  def find_gallery
    @a.get('http://www.acquavellagalleries.com/gallery') do |page|
      tmp = page.search(".postscript").first.inner_text.split("\n")
      address = {:title => tmp[0].strip,
                 :address1 => tmp[1].strip,
                 :city => tmp[2].split(",").first.strip,
                 :state => tmp[2].split(",").last.split(" ").first.strip,
                 :zipcode => tmp[2].split(",").last.split(" ").last.strip
      }
      address[:full] = address[:address1] + ", " + address[:city] + ", " + address[:state] + " " + address[:zipcode]
      address[:phone] = tmp[3].split(/[\s]+/).first.strip
      address[:fax] = tmp[4].split(/[\s]+/).first.strip
      tmp = CGI.unescape(tmp[4])
      first_index = tmp.index("mailto:")
      unless first_index.nil?
        last_index = tmp.index("\"", first_index + 1)
        address[:email] = tmp[(first_index + 7)..(last_index - 1)]
      end
      address[:map] = "http://maps.google.com/?q=#{address[:title] + ", " + address[:full]}"
      address[:web_url] = "http://www.acquavellagalleries.com"
      address[:long_description] = page.search(".gallery p").first.inner_text
      address[:working_hours_monday_start_time] = "10:00am"
      address[:working_hours_monday_end_time] = "5:00pm"
      address[:working_hours_tuesday_start_time] = "10:00am"
      address[:working_hours_tuesday_end_time] = "5:00pm"
      address[:working_hours_wednesday_start_time] = "10:00am"
      address[:working_hours_wednesday_end_time] = "5:00pm"
      address[:working_hours_thursday_start_time] = "10:00am"
      address[:working_hours_thursday_end_time] = "5:00pm"
      address[:working_hours_friday_start_time] = "10:00am"
      address[:working_hours_friday_end_time] = "5:00pm"
      address[:working_hours_saturday_start_time] = "10:00am"
      address[:working_hours_saturday_end_time] = "5:00pm"

      return address
    end
  end

  def find_exhibitions
    exhibitions = []
    url = "http://www.acquavellagalleries.com/exhibitions"
    @a.get(url) do |page|
      page.search("#midcol .container").first.search(".exh a").each do |text|
        link = Utils.get_full_url(text[:href], url)
        exhibitions << find_current_exhibition(link)
      end
    end

    return exhibitions
  end

  def find_artists
    artists = []
    url = "http://www.acquavellagalleries.com/artists"
    @a.get(url) do |page|
      page.search("#artists_list .artist div").each do |element|
        unless element.inner_text.strip == ""
          name = element.inner_text.strip.split("\n").first.strip
          link = element.search("a:contains('#{name}')").first
          artist = {:name => name}
          unless link.nil? || link[:href].to_s.strip == ""
            artist = find_artist(Utils.get_full_url(link[:href], url), artist)
          end

          artists << artist
        end
      end
    end

    return artists
  end

  def find_works()
    artists = {}
    url = "http://www.acquavellagalleries.com/catalogues/"
    @a.get(url) do |page|
      page.search(".catalogue").each do |element|
        tmp = element.search("span").inner_text.split("\n") rescue []
        link = Utils.get_full_url(element.search("a").first[:href], url) rescue nil
        artist_name = tmp.first.strip
        date = element.search("span em").first.inner_text.strip
        work = {}
        title = element.search("span strong").first.inner_text.strip
        work[:date] = date
        work[:title] = title unless title.nil? || title.strip.downcase == "view"
        work = find_work(link, work) unless link.nil?
        if artists[artist_name].nil?
          artists[artist_name] = []
        end 
        artists[artist_name] << work
      end
    end

    return artists
  end

  protected

  def find_artist(href, artist = {})
    @a.get(href) do |page|
      artist[:biography] = page.search("#midcol_left p").first.inner_text rescue nil
      if artist[:biography].nil?
      end
    end

    return artist
  end
  
  def find_work(url, work = {})
    @a.get(url) do |page|
      work[:image_url] = page.search("#media #right img").first[:src] rescue nil
    end

    return work
  end

  def find_current_exhibition(url, exhibition = {})
    @a.get(url) do |page|
      exhibition[:title] = page.search("#midcol_left h2").first.inner_text.strip
      exhibition[:artist] = page.search("#midcol_left h4").first.inner_text.strip
      time = page.search("#midcol_left em").first.inner_text.strip
      exhibition[:start_date] = time.split(",").first.split("-").first.strip
      exhibition[:end_date] = time.split("-").last.strip
      exhibition[:long_desc] = page.search("#midcol_left p").first.inner_text.strip
    end

    return exhibition
  end

  def find_biography(url)
    @a.get(url) do |page|
      return page.search("#content").first.inner_text
    end
  end
end

