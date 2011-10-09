require 'rubygems'
require 'mechanize'
require "cgi"
require "./utils"

class BarbaraMathes
  def initialize
    @a = Mechanize.new { |agent|
      agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; es-ES; rv:1.9.2.3) Gecko/20100401 Firefox/6.0.2'
    }
  end

  def find_gallery
    @a.get('http://www.barbaramathesgallery.com/contact/') do |page|
      tmp = page.search("#content_right #text_contact").first.inner_text.strip.split("\n")
      address = {:title => tmp[0].strip,
                 :address1 => tmp[1].strip,
                 :city => tmp[2].split(",").first.strip,
                 :state => tmp[2].split(",").last.split(" ").first.strip,
                 :zipcode => tmp[2].split(",").last.split(" ").last.strip
      }
      address[:full] = address[:address1] + ", " + address[:city] + ", " + address[:state] + " " + address[:zipcode]
      address[:phone] = tmp[3].split(":").last.strip
      address[:fax] = tmp[4].split(":").last.strip
      tmp = CGI.unescape(tmp[5])
      first_index = tmp.index("mailto:")
      unless first_index.nil?
        last_index = tmp.index("\"", first_index + 1)
        address[:email] = tmp[(first_index + 7)..(last_index - 1)]
      end
      address[:map] = "http://maps.google.com/?q=#{address[:title] + ", " + address[:full]}"
      address[:web_url] = "http://www.barbaramathesgallery.com"
      address[:long_description] = find_description

      return address
    end
  end

  def find_exhibitions
    exhibitions = []
    url = "http://www.barbaramathesgallery.com/exhibitions/"
    @a.get(url) do |page|
      i = 1
      while !page.search("#subhead#{i}").empty?
        exhibition = {}
        exhibition[:artist] = page.search("#subhead#{i} h1").first.inner_text.strip
        tmp = page.search("#subhead#{i}").first.inner_text.strip.split("\n")[2].strip
        exhibition[:start_date] = tmp.split(",").first.strip.split("-").first.strip
        exhibition[:end_date] = tmp.split(",").first.strip.split("-").last.strip + ", #{tmp.split(",").last.strip.to_i}"
        exhibitions << exhibition
        i += 1
      end
    end
    
    exhibitions << find_upcoming_exhibitions

    return exhibitions
  end

  def find_artists
    artists = []
    url = "http://www.barbaramathesgallery.com/artists/"
    @a.get(url) do |page|
      page.search("#artistlist .artistlistcol").each do |element|
        #tmp = element.inner_text.split("\n")
        element.children.each do |node|
          if node.name == "text" || node.name == "a"
            link = element.search("a:contains('#{node.inner_text.strip}')").first
            artist = {:name => node.inner_text.strip}
            unless link.nil? || link[:href].to_s.strip == ""
              artist[:works] = find_works(Utils.get_full_url(link[:href], url))
            end

            artists << artist
          end
        end
      end
    end

    return artists
  end

  protected

  def find_works(url)
    works = []
    @a.get(url) do |page|
      page.search("#scrollerContent .works a").each do |element|
        work = {}
        work[:image_url] = element[:href]
        tmp = element[:onclick]
        number = tmp.scan(/[\d]+/).first
        unless number.nil?
          tmp = page.search("#caption_#{number}").first.inner_text.strip.split("\n")
          work[:title] = page.search("#caption_#{number} i").first.inner_text.strip
          str = nil
          tmp.each do |text|
            if text.include?(" x ")
              str = text
              break
            end
          end
          
          unless str.nil?
            str = str.split(";").first
            tmp = Utils.get_dimensions(str)
            work = work.merge(tmp)
          end
        end
        
        works << work
      end
    end

    return works
  end

  def find_upcoming_exhibitions
    exhibitions = []
    url = "http://www.barbaramathesgallery.com/upcoming/"
    @a.get(url) do |page|
      tmp = page.search("#scrollerContent2").first
      tmp.children.each do |child|
        if child.inner_text.strip != "" && !child.inner_text.strip.index(" ").nil?
          exhibition = {}
          exhibition[:artist] = child.inner_text.split(":").first.strip
          str = child.inner_text.split(":").last.split(",")
          exhibition[:title] = str.first.strip
          exhibition[:start_date] = str[1].split("-").first.strip
          exhibition[:end_date] = str[1].split("-").last.strip + ", #{str.last.strip}"
          exhibitions << exhibition
        end
      end
    end

    return exhibitions
  end

  def find_biography(url)
    @a.get(url) do |page|
      return page.search("#content").first.inner_text
    end
  end
  
  def find_description
    url = "http://www.barbaramathesgallery.com/history/"
    @a.get(url) do |page|
      return page.search("#scrollerContent").first.inner_text.strip
    end
  end
end

