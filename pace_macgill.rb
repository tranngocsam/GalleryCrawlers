require 'rubygems'
require 'mechanize'
require "./utils"

class PaceMacgill
  def initialize
    @a = Mechanize.new { |agent|
      agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; es-ES; rv:1.9.2.3) Gecko/20100401 Firefox/6.0.2'
    }
  end

  def find_gallery
    @a.get('http://www.pacemacgill.com/contact.php') do |page|
      address = page.search("#content :nth-child(3)").inner_text.strip
      #hours = page.search("#content div:nth-child(4)").inner_text.strip
      inquiries = page.search("#content div:nth-child(9)").inner_text.strip
      inquiries = inquiries.gsub(inquiries[15], " ") if inquiries[15] && inquiries[15].ord == 160
      title = page.search("#masthead div:first img").first[:alt]
      tmp = address.split(",")
      address = {:full => address,
                 :title => title,
                 :address1 => tmp[0].strip + ", " + tmp[1].strip,
                 :city => tmp[2].split(" ").first.strip,
                 :zipcode => tmp[2].split(" ").last.strip
      }
      address[:phone] = inquiries.split(/[\s]+/)[1].strip
      address[:fax] = inquiries.split(/[\s]+/)[3].strip
      address[:email] = inquiries.split(/[\s]+/).last.strip
      address[:map] = "http://maps.google.com/?q=#{address[:full]}"
      address[:web_url] = "http://www.pacemacgill.com"
      address[:long_description] = find_description("http://www.pacemacgill.com/about_us.php")
      address[:working_hours_monday_start_time] = "9:30am"
      address[:working_hours_monday_end_time] = "5:30pm"
      address[:working_hours_tuesday_start_time] = "9:30am"
      address[:working_hours_tuesday_end_time] = "5:30pm"
      address[:working_hours_wednesday_start_time] = "9:30am"
      address[:working_hours_wednesday_end_time] = "5:30pm"
      address[:working_hours_thursday_start_time] = "9:30am"
      address[:working_hours_thursday_end_time] = "5:30pm"
      address[:working_hours_friday_start_time] = "9:30am"
      address[:working_hours_friday_end_time] = "5:30pm"
      address[:working_hours_saturday_start_time] = "10:00am"
      address[:working_hours_saturday_end_time] = "6:00pm"

      return address
    end
  end

  def find_exhibitions
    exhibitions = []
    @a.get("http://www.pacemacgill.com/") do |page|
      i = 0
      page.search(".imageLinks li").each do |text|
        exhibition = {}
        exhibition[:address] = text.inner_text
        link = Utils.get_full_url(page.search(".box a")[i][:href])
        exhibition = find_current_exhibition(link, exhibition)
        exhibitions << exhibition
	i += 1
      end
    end
    exhibitions << find_upcoming_exhibitions("http://www.pacemacgill.com/upcoming_exhibitions.php")

    return exhibitions
  end

  def find_artists
    artists = []
    url = "http://www.pacemacgill.com/artists.php"
    @a.get(url) do |page|
      content = page.search("#content").inner_text
      tmp = content.split(/[\s]+/)
      tmp.each do |artist_name|
        unless artist_name.strip == ""
          link = page.search("#content a:contains('#{artist_name.strip}')").first
          artist = {:name => artist_name.strip}
          unless link.nil? || link[:href].to_s.strip == ""
            artist = find_artist(Utils.get_full_url(link[:href], url), artist)
          end

          artists << artist
        end
      end
    end

    return artists
  end

  protected

  def find_work(href)
    work = {}
    @a.get(href) do |page|
      image_tag = page.search("#content div:first img")[0]
      work[:image_url] = Utils.get_full_url(image_tag[:src], href)
      work[:title] = image_tag[:alt]
      work[:long_description] = page.search("#content #descriptions")[0].inner_text
      tmp = work[:long_description].split("\n")
      tmp = tmp[3].split(" ") rescue nil
      unit = tmp.pop unless tmp.nil?
      tmp = tmp.join(" ") unless tmp.nil?
      tmp = tmp.split("x") unless tmp.nil?
      unless tmp.nil?
        x = tmp[0]
        y = tmp[1]
        tmp = x.split(" ")
        x = tmp[0].to_f

        unless tmp[1].nil? || !tmp.inclde?("/")
          tmp = tmp.split("/")
          x += tmp[0].to_f/tmp[1].to_f
        end

        tmp = y.split(" ")
        y = tmp[0].to_f

        unless tmp[1].nil? || !tmp.inclde?("/")
          tmp = tmp.split("/")
          y += tmp[0].to_f/tmp[1].to_f
        end

        work[:width] = x
        work[:height] = y
        work[:unit] = unit
      end
    end

    return work
  end

  def find_description(long = true)
    @a.get('http://www.pacemacgill.com/about_us.php') do |page|
      return page.search("#content").inner_text.strip
    end
  end
  
  def find_artist(href, artist = {})
    @a.get(href) do |page|
      works = []
      page.search(".scrollableArea span a").each do |link|
        works << find_work(Utils.get_full_url(link[:href], href))
      end
      artist[:works] = works
      artist[:biography] = find_biography(Utils.get_full_url(page.search("#content a:contains('biography')").first[:href], href))
    end

    return artist
  end

  def find_current_exhibition(url, exhibition = {})
    @a.get(url) do |page|
      exhibition[:title] = page.search("#content div p:first img")[0][:alt]
      exhibition[:long_desc] = find_description(Utils.get_full_url(page.search("#nav-press-release")[0][:href], url))
    end

    return exhibition
  end

  def find_upcoming_exhibitions(url)
    exhibitions = []
    @a.get(url) do |page|
      lines = page.search("#content div p")
      for i in 0..(lines.length - 1) do
        if lines[i].inner_text.downcase.index(/jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec/)
          exhibition = {:time => lines[i].inner_text.strip}
          tmp = lines[i + 1]
          unless tmp.nil?
            exhibition[:artist] = tmp.inner_text.split(":").first
            exhibition[:name] = tmp.inner_text.split(":").last
          end
	  description_url = nil
	  description_url = Utils.get_full_url(lines[i + 2].search("a").first[:href], url) unless lines[i + 2].nil? || lines[i + 2].search("a").empty?
          exhibition[:long_desc] = find_exhibition_description(description_url) unless lines[i + 2].nil? || description_url.nil?
          exhibitions << exhibition
        end unless lines[i].inner_text.strip == ""
      end
    end
    return exhibitions
  end

  def find_description(url)
    @a.get(url) do |page|
      content = page.search("#content div").inner_text
      tmp = content.split("\n")
      tmp.pop
      return tmp.join("\n")
    end
  end

  def find_biography(url)
    @a.get(url) do |page|
      return page.search("#content").first.inner_text
    end
  end

  def find_exhibition_description(url)
    @a.get(url) do |page|
      return page.search("#content").inner_text
    end
  end
end

