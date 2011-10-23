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
    url = 'http://www.gagosian.com/contact/'
     full_address=[]
    @a.get(url) do |page|
      arr_add = page.search("#content").inner_html.split("</address>")
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
        address[:hours] = tmp[6].split(":").last.strip
        address[:full] = address[:street] + "," + address[:city] + "," + address[:state] + "," + address[:zipcode]        
        page.search("#content address a.link").each do |text| 
         address[:map] =  text[:href]
        end
        address[:web_url] = "http://www.gagosian.com"
        full_address<< address        
    end        
      }
    end
    return full_address
  end
  
  def find_exhibitions
    url = "http://www.gagosian.com/current/"   
    url1 = "http://www.gagosian.com/past/"
    url2="http://www.gagosian.com/upcoming/"
    exhibition = []
    @a.get(url) do |page|
       page.search("#curr_cont .exhib_current .exhiblink a").each do |text|
         link  = Utils.get_full_url(text[:href],url)
         exhibition <<  find_exhibition(link)          
       end
    end
    @a.get(url1) do |page|
      page.search("#twocol_right .objvert .d-thumb a").each do |text|
        link  = Utils.get_full_url(text[:href],url)
         exhibition <<  find_exhibition(link)          
      end
    end
      @a.get(url2) do |page|
      page.search("#twocol_right .objvert .d-thumb a").each do |text|
         link  = Utils.get_full_url(text[:href],url)
         if link.nil?
            upcoming = {}
            upcoming[:address] = page.search("#twocol_right .objvert .gallery").inner_text
            upcoming[:title] =  page.search("#twocol_right .objvert .name").inner_text
              year = page.search("#twocol_right .objvert .date").split("-")[1].split(",")[1]
              upcoming[:start_date] = page.search("#twocol_right .objvert .date").split("-")[0] + "," + year
              upcoming[:end_date] = page.search("#twocol_right .objvert .date").split("-")[1] 
              exhibition << upcoming
         else
           exhibition <<  find_exhibition(link)
        end
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
  
  def find_shops
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
          work = find_shop(link,work) unless link.nil?
          if artists[artist_name].nil?
            artists[artist_name]=[]
          end
          artists[artist_name] << work
        end
    end
    return artists
  end
  
  protected
  
  def find_exhibition(url,exhibitions={})
    @a.get(url) { |page|       
        title_start_end_date = Utils.remove_html_tags(page.search("#subhead1 h3").inner_html).split("\n")
        subinfo = Utils.remove_html_tags(page.search("#subinfo").inner_html).split("\n")
        add = subinfo[0,3]
        for item in 0...add.length
          if add[item] == ""
            add[item,1]=[]
          end
        end
        subinfo.each { |i|           
          unless i.scan("Hours").last.nil?
            exhibitions[:hours] = i.split(":")[1]
            break
          end
        }
        exhibitions[:address] = add
        exhibitions[:artist] = page.search("#subhead1 .gNor").inner_text  
        exhibitions[:title] = title_start_end_date.first  
        exhibitions[:start_date] = title_start_end_date.last.split("-").first + "," +title_start_end_date.last.split("-").last.split(",").last
        exhibitions[:end_date] = title_start_end_date.last.split("-").last
        tmp =page.search("#threecol_mid").inner_html.split("<hr>")[0]
       if !tmp.empty?
        #Vong lap nay xoa di cac ky tu trang con thua lai
        tmp1=Utils.remove_html_tags(tmp).split("\n")
          for item in 0...tmp1.length/2
            if tmp1[item] == "" 
              tmp1[item,1]=[]
            end        
          end                 
          for item in 0...tmp1.length/2
            if tmp1[item] == "" 
              tmp1[item,1]=[]
            end        
          end
          index = 0
          for i in 0...tmp1.length/2 
            unless tmp1[i].scan("Download").last.nil?
                index = i                
            end
          end
          exhibitions[:full_desc] =tmp1[index+1,tmp1.length].to_s        
       end
    }
    return exhibitions
  end
  
  def find_artist(url,artist={})
    @a.get(url) do |page|      
      artist[:biography] = page.search("div#threecol_mid").inner_text
      artist[:work] = find_work(url)
    end
    return artist
  end
  
  def find_work(url)
    work = {}
    
    @a.get(url) do |page|
      arr = Utils.remove_html_tags(page.search("#p_artists").inner_html).split("\n")
      arr=arr.compact
      
        arr_image_data =  arr[arr.length - 14,1].inspect      
        if arr_image_data.eql?("[\"\"]")
        else
          all_img = arr_image_data.split(",")[1,arr_image_data.length-1]
          path ="http:" +  arr_image_data.split(",").first.split(":")[2].to_s.delete("\"").delete("\\")          
          list_image_url = []
          for i in 0...all_img.length
          arr_img_name =  all_img[i].split("\\\"f1\\\"")[1,1]
           unless arr_img_name.empty?
             image_name = arr_img_name.to_s.delete("[]\":\\")                
             if image_name.end_with?(".jpg")
                image_url =path+ image_name
                list_image_url << image_url               
            end           
           end
          end
           work[:image_url] =list_image_url
          des_arr_all = arr_image_data.split("\\\"c\\\"")
          list_short_des = []
          list_title =[]
          des_arr_all[1,des_arr_all.length-1].each { |item|
            list_short_des << item.split("}")[0].delete(":")
            list_title << item.split("}")[0].split(",")[0].split("\"")[1]
             item.split("}")[0].delete(":").split("\\\\n").each { |item2|
              unless item2.scan("inches").inspect.eql?("[]")
                  tmp = item2.split("(").last.delete(")").delete("\\").delete("\"")                
                  work = work.merge(Utils.get_dimensions(tmp.strip))
              end            
            }
          }
          work[:short_description] = list_short_des
          work[:title] = list_title
        end
    end
    return work
  end
  
  def find_shop(url,work={})
    @a.get(url) do |page|
      work[:date] = page.search("#subinfo").inner_text.split("\n").first.strip rescue nil
      work[:image] = page.search("#threecol_mid .imgCap img").first[:src] rescue nil      
    end
    return work
  end
  
end
