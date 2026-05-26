require 'nokogiri'

class PaintingsExtractor
  GOOGLE_BASE_URL = 'https://www.google.com'

  # Google has used two generations of CSS class names for the artworks carousel.
  # Both layouts carry identical data; only the class names differ.
  LAYOUTS = [
    # Older layout (e.g. Van Gogh page fetched late 2024)
    { item: '.iELo6', name: '.pgNMRc', ext: '.cxzHyb', img: 'img.taFZJe' },
    # Newer layout (e.g. Monet / Picasso pages fetched 2025)
    { item: '.TILZre', name: '.yfEcJe', ext: '.DWyOHb', img: 'img.pHjwVc' },
  ].freeze

  def initialize(html_content)
    @doc      = Nokogiri::HTML(html_content)
    @raw_html = html_content
    @image_map = build_image_map
  end

  def extract
    layout = detect_layout
    return [] unless layout

    @doc.css(layout[:item]).map do |item|
      anchor = item.at_css('a')
      next unless anchor

      img        = item.at_css(layout[:img])
      name       = item.at_css(layout[:name])&.text&.strip
      ext_text   = item.at_css(layout[:ext])&.text&.strip
      extensions = ext_text && !ext_text.empty? ? [ext_text] : nil
      link       = resolve_link(anchor['href'])
      image      = resolve_image(img)

      result = { name: name, extensions: extensions, link: link }
      result[:image] = image if image
      result
    end.compact
  end

  private

  def detect_layout
    LAYOUTS.find { |l| @doc.at_css(l[:item]) }
  end

  # Build a map from img element ID → base64 data URI by scanning all
  # _setImagesSrc(...) inline scripts. Google embeds the first N thumbnails
  # directly in the page this way; the rest use data-src (external URLs).
  # Handles both call signatures:
  #   _setImagesSrc(ii, s, r)   — older pages
  #   _setImagesSrc(ii, s)      — newer pages
  def build_image_map
    pattern = /\(function\(\)\{var s='(data:image\/[^']+)';var ii=\[([^\]]+)\];(?:var r='[^']*';)?_setImagesSrc\(ii,s(?:,r)?\);\}\)\(\);/
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
    return @image_map[img_id] if img_id && @image_map.key?(img_id)
    nil
  end
end
