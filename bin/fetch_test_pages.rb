#!/usr/bin/env ruby
# Fetches real Google SERP HTML pages via SerpApi and saves them to files/
# Usage: ruby bin/fetch_test_pages.rb YOUR_API_KEY
#
# SerpApi docs: https://serpapi.com/search-api

require 'net/http'
require 'uri'
require 'json'

SERPAPI_ENDPOINT = 'https://serpapi.com/search'
FILES_DIR = File.expand_path('../files', __dir__)

QUERIES = [
  { query: 'Claude Monet paintings',   filename: 'claude-monet-paintings.html'   },
  { query: 'Pablo Picasso paintings',  filename: 'pablo-picasso-paintings.html'  },
]

def fetch_html(query, api_key)
  uri = URI(SERPAPI_ENDPOINT)
  uri.query = URI.encode_www_form(
    q:       query,
    hl:      'en',
    gl:      'us',
    output:  'html',
    api_key: api_key,
  )

  puts "  GET #{SERPAPI_ENDPOINT}?q=#{URI.encode_www_form_component(query)}&hl=en&gl=us&output=html"

  response = Net::HTTP.get_response(uri)

  if response.code != '200'
    body = JSON.parse(response.body) rescue { 'error' => response.body }
    raise "SerpApi error (HTTP #{response.code}): #{body['error'] || response.body}"
  end

  response.body
end

def main
  api_key = ARGV[0] || ENV['SERPAPI_KEY']

  if api_key.nil? || api_key.strip.empty?
    abort <<~MSG
      Usage: ruby bin/fetch_test_pages.rb YOUR_API_KEY
         or: SERPAPI_KEY=your_key ruby bin/fetch_test_pages.rb
    MSG
  end

  puts "Fetching #{QUERIES.length} pages from SerpApi...\n\n"

  QUERIES.each do |item|
    print "Fetching '#{item[:query]}'... "
    $stdout.flush

    begin
      html     = fetch_html(item[:query], api_key)
      out_path = File.join(FILES_DIR, item[:filename])
      File.write(out_path, html)
      puts "saved to files/#{item[:filename]} (#{(html.bytesize / 1024.0).round(1)} KB)"
    rescue => e
      puts "FAILED\n  #{e.message}"
      exit 1
    end
  end

  puts "\nDone. Run the test suite with:\n  bundle exec rspec spec/"
end

main
