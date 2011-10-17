require 'rubygems'
require 'mechanize'
require "cgi"
require "./utils"


class Gagosian
  def initialize
       @a = Mechanize.new { |agent|
      agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; es-ES; rv:1.9.2.3) Gecko/20100401 Firefox/6.0.2'
    }
  end
  def find_gallery
      full_address={}
    @a.get('http://www.gagosian.com/contact/') do |page|
      arr_add = page.search("#content").inner_html.split("</address>")        
      i=0
      arr_add.each { |add|        
        tmp= Utils.remove_html_tags(add).split("\n")
        #Loai di phan tu rong
        if !tmp.empty?
        #Vong lap nay xoa di cac ky tu trang con thua lai
          for item in 0...tmp.length
            if tmp[item] == "" 
              tmp[item,1]=[]
            end        
          end         
        address={}
        address[:title] = tmp[0].strip  
        address[ :street] = tmp[1].strip
        address[:city] = tmp[2].split(",").first.strip
        address[:state] = tmp[2].split(",").last.split(/[\d]+/).first.strip
        address[:zipcode] = tmp[2].split(",").last.scan(/[\d]+/).first.strip
        address[:phone] = tmp[3].split(" ").last.strip
        address[:fax] = tmp[4].split(" ").last.strip
        address[:email] = tmp[5].strip
        address[:full] = address[:street] + "," + address[:city] + "," + address[:state] + "," + address[:zipcode]
        address[:map] = "http://maps.google.com/?q=#{address[:full]}"
        address[:web_url] = "http://www.gagosian.com"
        full_address[i]= address
        i+=1
    end        
      }
    end
    return full_address
  end
  
  def find_exhibitions
    url = "http://www.gagosian.com/current/"    
    exhibition = []
    @a.get(url) do |page|
       page.search("#curr_cont .exhib_current .exhiblink a").each do |text|
         link  = Utils.get_full_url(text[:href],url)
         exhibition <<  find_current_exhibition(link)          
       end
    end
    return exhibition
  end
  
  def find_artists
    url = "http://www.gagosian.com/artists/"
    artists = []   
    @a.get(url){|page|      
      page.search("#artist_showing div a").each do |text|
        unless text.nil?
          name = text.inner_text.strip
          artist = {:name => name}
          link = Utils.get_full_url(text[:href],url)          
          artist =  find_artist(link,artist)
          artists << artist
        end
      end      
    }
    return artists
  end
  
  def find_works
    artists = {}
    url = "http://www.gagosian.com/shop/"
    @a.get(url) do |page|
        page.search("#twocol_right .publication_list").each do |element|
          tmp = element.search("a").last.inner_text.split("\n") #rescue []          
          link = Utils.get_full_url(element.search("a").first[:href],url) rescue nil          
          artist_name = tmp.first.strip
          title = tmp[1].strip rescue nil          
          work = {}       
          work[:title]=title
          work = find_work(link,work) unless link.nil?
          if artists[artist_name].nil?
            artists[artist_name]=[]
          end
          artists[artist_name] << work
        end
    end
    return artists
  end
  
  protected
  
  def find_current_exhibition(url,exhibitions={})
    @a.get(url) { |page|       
        title_start_end_date = Utils.remove_html_tags(page.search("#subhead1 h3").inner_html).split("\n")
        exhibitions[:title] = title_start_end_date.first
        exhibitions[:artist] = page.search("#subhead1 .gNor").inner_text  
        exhibitions[:startdate] = title_start_end_date.last.split("-").first + "," +title_start_end_date.last.split("-").last.split(",").last
        exhibitions[:enddate] = title_start_end_date.last.split("-").last+"," +title_start_end_date.last.split("-").last.split(",").last
        tmp = Utils.remove_html_tags(page.search("#threecol_mid").inner_html).split("\n")
       if !tmp.empty?
        #Vong lap nay xoa di cac ky tu trang con thua lai
          for item in 0...tmp.length/2
            if tmp[item] == "" 
              tmp[item,1]=[]
            end        
          end       
          tmp[0,2]=[]
          for item in 0...tmp.length/2
            if tmp[item] == "" 
              tmp[item,1]=[]
            end        
          end
        exhibitions[:full_desc] = tmp
       end
    }
    return exhibitions
  end
  
  def find_artist(url,artist={})
    @a.get(url) do |page|
      #arr = page.search("#threecol_mid").inner_text.split("\n")
      #str = page.search("#threecol_mid").inner_text.split("\n")[arr.length-1,1].last      
      artist[:biography] = page.search("div#threecol_mid").inner_text
    end
    return artist
  end
  
  def find_work(url,work={})
    @a.get(url) do |page|
      work[:date] = page.search("#subinfo").inner_text.split("\n").first.strip rescue nil
      work[:image] = page.search("#threecol_mid .imgCap img").first[:src] rescue nil      
    end
    return work
  end
  
end
