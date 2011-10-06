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
end