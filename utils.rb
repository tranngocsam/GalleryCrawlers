class Utils

  def self.get_full_url(url, current_page = nil)
    return url if current_page.nil? || current_page.strip == ""
    return url if url[0..6] == "http://"
    tmp = current_page.split("/")

    if current_page.strip[current_page.strip.length - 1] != "/"
      tmp.pop
    end

    if current_page.index("/", 7).nil?
      return tmp.join("/") + "/" + url
    else
      if url[0] == "/"
        last_index = current_page.index("/", 7)
        return current_page[0..(last_index - 1)] + url
      end
    end

    url_parts = url.split("/")
    count = 0
    url_parts.each do |part|
      if part == ".."
        count += 1
      end
    end

    if count > 0
      count.times.each do
        tmp.pop
        url_parts.shift
      end
    end

    return tmp.join("/") + "/" + url_parts.join("/")
  end
  
  def self.remove_html_tags(html)
    return nil if html.nil?
    html = html.strip.gsub(/<\/?[i|b|u|a|span|em|big|strong|small|font|strike|tt]>/, "")
    return html.gsub(/<\/?[^>]*>/, "\n").strip
  end
  
  def Utils.get_dimensions(str, dimension_split = "x", fraction_split = " ")
    work = {}
    unless str.nil? || str.strip == ""
      work[:unit] = str.split(/[\s]+/).last
      x = str.split(dimension_split).first
      y = str.split(dimension_split).last
      numbers = x.split(fraction_split)
      x = numbers[0].to_f

      unless numbers[1].nil? || !numbers[1].include?("/")
        numbers = numbers[1].split("/")
        x += numbers[0].to_f/numbers[1].to_f
      end

      numbers = y.split(fraction_split)
      y = numbers[0].to_f

      unless numbers[1].nil? || !numbers[1].include?("/")
        numbers = numbers[1].split("/")
        y += numbers[0].to_f/numbers[1].to_f
      end

      work[:width] = x
      work[:height] = y
    end
    
    return work
  end
end