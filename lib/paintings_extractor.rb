require 'nokogiri'

class PaintingsExtractor
  GOOGLE_BASE_URL = 'https://www.google.com'

  def initialize(html_content)
    @doc = Nokogiri::HTML(html_content)
    @raw_html = html_content
    @image_map = build_image_map
  end

  def extract
    @doc.css('.iELo6').map do |item|
      anchor = item.at_css('a')
      next unless anchor

      img   = item.at_css('img.taFZJe')
      name  = item.at_css('.pgNMRc')&.text&.strip
      ext   = item.at_css('.cxzHyb')&.text&.strip
      link  = resolve_link(anchor['href'])
      image = resolve_image(img)

      extensions = ext && !ext.empty? ? [ext] : nil
      result = { name: name, extensions: extensions, link: link }
      result[:image] = image if image
      result
    end.compact
  end

  private

  # Build a map from img element ID to base64 data URI extracted from
  # inline _setImagesSrc(...) scripts — only images already embedded in
  # the page (no extra HTTP requests needed).
  def build_image_map
    pattern = /\(function\(\)\{var s='(data:image\/[^']+)';var ii=\[([^\]]+)\];var r='[^']*';_setImagesSrc\(ii,s,r\);\}\)\(\);/
    map = {}
    @raw_html.scan(pattern) do |src, ids_str|
      ids_str.scan(/'([^']+)'/) { |id,| map[id] = src }
    end
    map
  end

  def resolve_link(href)
    return nil unless href
    href.start_with?('http') ? href : "#{GOOGLE_BASE_URL}#{href}"
  end

  def resolve_image(img)
    return nil unless img

    img_id = img['id']
    # Prefer the already-embedded base64 image
    return @image_map[img_id] if img_id && @image_map.key?(img_id)

    # Skip images that require an extra HTTP request
    nil
  end
end
