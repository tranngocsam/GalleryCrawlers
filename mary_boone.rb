require 'rubygems'
require 'mechanize'
require 'utils'

class MaryBoone
  def initialize
    @a = Mechanize.new { |agent|
      agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; es-ES; rv:1.9.2.3) Gecko/20100401 Firefox/6.0.2'
    }
  end

  def find_gallery
    @a.get('http://www.maryboonegallery.com/contact.html') do |page|
      address = page.search("p.ex_copy").inner_text.strip
      tmp = address.split("\n")
      address = tmp.map {|text| text.strip}.join(", ")
      address = {:full => address,
                 :title => tmp[0].strip,
                 :address1 => tmp[1].strip,
                 :city => tmp[2].split(",").first.strip,
                 :state => tmp[2].split(",").last.split(" ").first.strip,
                 :zipcode => tmp[2].split(",").last.split(" ").last.strip
                 }

      more_info = page.search("//span[contains(text(), 'Telephone')]").inner_text
      tmp = more_info.split("\n")
      address[:phone] = tmp[0].split(":").last.strip
      address[:fax] = tmp[1].split(":").last.strip
      address[:email] = tmp[0].split(":").last.strip
      address[:map] = "http://maps.google.com/?q=#{address[:full]}"
      address[:web_url] = "http://www.maryboonegallery.com"
      address[:long_description] = find_description
      
      return address
    end
  end

  def find_description(long = true)
    @a.get('http://www.maryboonegallery.com/about.html') do |page|
      return page.search("table table table").inner_text.strip
    end
  end

  def find_exhibitions
    time = Time.now
    exhibitions = []
    @a.get("http://www.maryboonegallery.com/exhibitions/#{time.year}-#{time.year + 1}/index.html") do |page|
      page.search("table td.bright_text").each do |text|
        exhibition = {}
        exhibition[:title] = text.search("a").first.inner_text.split("\n").map {|text| text.strip}.join(" ")
        exhibition[:time] = text.search("a").last.inner_text.split("\n").first
        exhibitions << exhibition
      end
    end

    return exhibitions
  end

  def find_artists
    artists = []
    url = "http://www.maryboonegallery.com/artists.html"
    @a.get(url) do |page|
      page.search("#artistsTable1 tr").each do |tr|
        tr.search("td").each do |td|
          artists << find_artist(Utils.get_full_url(td.search("a")[0][:href], url))
        end
      end
    end

    return artists
  end

  def find_artist(href)
    artist = {}
    @a.get(href) do |page|
      works = []
      page.search("table tr:nth-child(2) table tr:nth-child(2) table tr td a").each do |link|
        works << find_work(Utils.get_full_url(link[:href], href))
      end
      artist[:works] = works
      artist[:name] = page.search("table tr:nth-child(2) table tr:nth-child(4) img")[0][:alt]
      artist[:biography] = page.search("table tr:nth-child(2) table table tr td:nth-child(3)")[1].inner_text
      artist[:web_url] = artist[:biography].split("\n").last
    end

    return artist
  end

  def find_work(href)
    work = {}
    @a.get(href) do |page|
      image_tag = page.search("table tr:nth-child(2) table tr:nth-child(2) td:nth-child(2) img")[0]
      work[:image_url] = Utils.get_full_url(image_tag[:src], href)
      work[:title] = image_tag[:alt]
      work[:long_description] = page.search("table tr:nth-child(2) table tr:nth-child(2) td:nth-child(4)")[0].inner_text
    end

    return work
  end
end

