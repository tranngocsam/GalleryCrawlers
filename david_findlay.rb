require 'rubygems'
require 'mechanize'
require "cgi"
require "./utils"

class DavidFindlay
  def initialize
    @a = Mechanize.new { |agent|
      agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; es-ES; rv:1.9.2.3) Gecko/20100401 Firefox/6.0.2'
    }
  end

  def find_gallery
    @a.get('http://www.davidfindlayjr.com/gallery.php') do |page|
      tmp = Utils.remove_html_tags(page.search("#pics p").first.inner_html).split("\n")
      puts "Line 16 #{tmp.inspect}"
      address = {:title => "David Findlay Jr Gallery",
                 :address1 => tmp[0].strip,
                 :city => tmp[1].split(",").first.strip,
                 :state => tmp[1].split(",").last.split(/[\d]+/).first.strip,
                 :zipcode => tmp[1].split(",").last.scan(/[\d]+/).first
      }
      address[:full] = address[:address1] + ", " + address[:city] + ", " + address[:state] + " " + address[:zipcode]
      address[:phone] = tmp[2].split(":").last.strip
      address[:fax] = tmp[3].split(":").last.strip
      address[:map] = "http://maps.google.com/?q=#{address[:title] + ", " + address[:full]}"
      address[:web_url] = "http://www.davidfindlayjr.com"
      address[:long_description] = page.search("#picNav").first.inner_text

      return address
    end
  end

  def find_exhibitions
    exhibitions = []
    url = "http://www.davidfindlayjr.com/exhibits.php"
    @a.get(url) do |page|
      if page.search("body").first.inner_text.downcase.include?("current exhibit")
        table = page.search("table").first
        table.search("tr").each do |row|
          exhibition = {}
          tmp = Utils.remove_html_tags(row.search("td").last.inner_html).split("\n")
          exhibition[:title] = tmp.first.strip + ", " + tmp[1].strip
          exhibition[:start_date] = tmp.last.split("-").first.strip
          exhibition[:end_date] = tmp.last.split("-").last.strip
          exhibitions << exhibition
        end
      end

      if page.search("body").first.inner_text.downcase.include?("upcoming exhib")
        table = page.search("table #content1 #listing").first

        table.search("tr").each do |row|
          exhibition = {}
          tmp = Utils.remove_html_tags(row.search("td").last.inner_html).split("\n")
          exhibition[:title] = tmp.first.strip + ", " + tmp[1].strip
          exhibition[:start_date] = tmp.last.split("-").first.strip
          exhibition[:end_date] = tmp.last.split("-").last.strip
          exhibitions << exhibition
        end
      end
    end

    return exhibitions
  end

  def find_artists
    artists = []
    url = "http://www.davidfindlayjr.com/artists.php"
    @a.get(url) do |page|
      page.search("#main table tr td").each do |element|
        element.children.each do |node|
          if (node.name == "text" || node.name == "a") && node.inner_text.strip != ""
            link = element.search("a:contains('#{node.inner_text.strip}')").first
            artist = {:name => node.inner_text.strip}
            unless link.nil? || link[:href].to_s.strip == ""
              artist = find_artist(Utils.get_full_url(link[:href], url), artist)
            end

            artists << artist
          end
        end
      end
    end

    return artists
  end

  protected

  def find_artist(url, artist = {})
    @a.get(url) do |page|
      a = page.search("a:contains('BIOGRAPHY')").first
      unless a.nil?
        id = a[:onmousedown].scan(/'.+'/).last.gsub("'", "")
        artist[:biography] = find_biography("http://www.davidfindlayjr.com/articlePopper.php?id=#{id}")
        works = []
        page.search(".thumbs a").each do |element|
          link = element[:onclick].scan(/'[^']*'/).last.gsub("'", "")
          link = Utils.get_full_url(link, url)
          works << find_work(link)
        end
        artist[:works] = works
      end
    end
    
    return artist
  end

  def find_biography(url)
    @a.get(url) do |page|
      p_tags = page.search("p").sort {|a, b| b.inner_text.length <=> a.inner_text.length}
      return p_tags.first.inner_text
    end
  end

  def find_work(url)
    work = {}
    @a.get(url) do |page|
      link = page.search("#enlarge").first
      id = link[:onclick].scan(/[\d]+/).first
      work[:image_url] = find_work_image(id)
      work[:short_description] = Utils.remove_html_tags(page.search("table tr:first td:last").inner_html)
      tmp = work[:short_description].split("\n")
      work[:title] = tmp[0]
      work = work.merge(Utils.get_dimensions(tmp.last.strip))
    end
    
    return work
  end
  
  def find_work_image(id)
    url = "http://www.davidfindlayjr.com/imagePop.php?id=#{id}"
    @a.get(url) do |page|
      return Utils.get_full_url(page.search("table tr:first td:first img").first[:src], url)
    end
  end
end

