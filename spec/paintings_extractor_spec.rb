require 'json'
require_relative '../lib/paintings_extractor'

FILES_DIR = File.expand_path('../files', __dir__)

def load_html(filename)
  File.read(File.join(FILES_DIR, filename))
end

def load_json(filename)
  JSON.parse(File.read(File.join(FILES_DIR, filename)))
end

# Shared examples for any Google carousel page.
# Every page — whether paintings, anime, or anything else — must satisfy
# these structural guarantees.
RSpec.shared_examples 'a carousel extractor' do
  it 'returns a non-empty Array' do
    expect(results).to be_an(Array)
    expect(results).not_to be_empty
  end

  it 'extracts a non-empty name string for every item' do
    results.each do |item|
      expect(item[:name]).to be_a(String), "name should be a String"
      expect(item[:name]).not_to be_empty,  "name should not be empty"
    end
  end

  it 'extracts extensions as an Array or nil for every item' do
    results.each do |item|
      expect([Array, NilClass]).to include(item[:extensions].class),
        "extensions for '#{item[:name]}' should be Array or nil"
    end
  end

  it 'extracts a full https://www.google.com link for every item' do
    results.each do |item|
      expect(item[:link]).to be_a(String),
        "link for '#{item[:name]}' should be a String"
      expect(item[:link]).to start_with('https://www.google.com'),
        "link for '#{item[:name]}' should be a full Google URL"
    end
  end

  it 'only includes images that are already embedded in the HTML (no external URLs)' do
    results.each do |item|
      next unless item.key?(:image)
      expect(item[:image]).to start_with('data:image/'),
        "'#{item[:name]}' image should be a base64 data URI, not an external URL"
    end
  end
end

# ─── Van Gogh paintings (primary challenge) ───────────────────────────────────

RSpec.describe PaintingsExtractor, 'Van Gogh paintings' do
  let(:html)     { load_html('van-gogh-paintings.html') }
  let(:expected) { load_json('expected-array.json')['artworks'] }
  let(:results)  { described_class.new(html).extract }

  include_examples 'a carousel extractor'

  it 'extracts exactly 47 artworks' do
    expect(results.length).to eq(expected.length)
  end

  it 'extracts all painting names in order' do
    expect(results.map { |a| a[:name] }).to eq(expected.map { |a| a['name'] })
  end

  it 'matches expected extensions for every artwork' do
    results.each_with_index do |artwork, i|
      expect(artwork[:extensions]).to eq(expected[i]['extensions']),
        "extensions mismatch for '#{artwork[:name]}'"
    end
  end

  it 'matches expected link for every artwork' do
    results.each_with_index do |artwork, i|
      expect(artwork[:link]).to eq(expected[i]['link']),
        "link mismatch for '#{artwork[:name]}'"
    end
  end

  it 'first artwork is The Starry Night' do
    expect(results.first[:name]).to eq('The Starry Night')
  end

  it 'first 8 artworks have embedded base64 thumbnails' do
    results.first(8).each do |artwork|
      expect(artwork[:image]).to be_a(String),
        "'#{artwork[:name]}' should have an embedded image"
      expect(artwork[:image]).to start_with('data:image/')
    end
  end

  it 'artworks beyond the first 8 have no image key (would require HTTP request)' do
    results.drop(8).each do |artwork|
      expect(artwork).not_to have_key(:image),
        "'#{artwork[:name]}' image requires an HTTP request and should be omitted"
    end
  end

  it 'first artwork image matches expected exactly' do
    expect(results.first[:image]).to eq(expected.first['image'])
  end
end

# ─── Claude Monet paintings (real SERP page, newer carousel layout) ──────────

RSpec.describe PaintingsExtractor, 'Claude Monet paintings' do
  let(:html)    { load_html('claude-monet-paintings.html') }
  let(:results) { described_class.new(html).extract }

  before(:all) do
    skip 'claude-monet-paintings.html not present — run: ruby bin/fetch_test_pages.rb YOUR_KEY' \
      unless File.exist?(File.join(FILES_DIR, 'claude-monet-paintings.html'))
  end

  include_examples 'a carousel extractor'

  it 'extracts more than one item' do
    expect(results.length).to be > 1
  end
end

# ─── Pablo Picasso paintings (real SERP page, newer carousel layout) ──────────

RSpec.describe PaintingsExtractor, 'Pablo Picasso paintings' do
  let(:html)    { load_html('pablo-picasso-paintings.html') }
  let(:results) { described_class.new(html).extract }

  before(:all) do
    skip 'pablo-picasso-paintings.html not present — run: ruby bin/fetch_test_pages.rb YOUR_KEY' \
      unless File.exist?(File.join(FILES_DIR, 'pablo-picasso-paintings.html'))
  end

  include_examples 'a carousel extractor'

  it 'extracts more than one item' do
    expect(results.length).to be > 1
  end
end
