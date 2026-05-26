#!/usr/bin/env ruby
# Runs PaintingsExtractor on every HTML file in files/ and writes the
# results as JSON to results/<filename>.json
#
# Usage:
#   ruby bin/extract.rb                  # process all files/*.html
#   ruby bin/extract.rb van-gogh         # process files/van-gogh-paintings.html only

require 'json'
require_relative '../lib/paintings_extractor'

FILES_DIR  = File.expand_path('../files',   __dir__)
RESULTS_DIR = File.expand_path('../results', __dir__)

FileUtils.mkdir_p(RESULTS_DIR)

pattern = ARGV[0] ? "*#{ARGV[0]}*.html" : '*.html'
html_files = Dir.glob(File.join(FILES_DIR, pattern)).sort

if html_files.empty?
  abort "No HTML files matched '#{pattern}' in #{FILES_DIR}"
end

html_files.each do |path|
  basename    = File.basename(path, '.html')
  output_path = File.join(RESULTS_DIR, "#{basename}.json")

  print "Extracting #{basename}... "
  $stdout.flush

  html     = File.read(path)
  artworks = PaintingsExtractor.new(html).extract

  File.write(output_path, JSON.pretty_generate({ artworks: artworks }))
  puts "#{artworks.length} artworks → results/#{basename}.json"
end
