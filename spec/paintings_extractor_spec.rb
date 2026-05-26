require 'json'
require_relative '../lib/paintings_extractor'

FILES_DIR = File.expand_path('../files', __dir__)

# ─── helpers ──────────────────────────────────────────────────────────────────

def load_html(filename)
  File.read(File.join(FILES_DIR, filename))
end

def load_json(filename)
  JSON.parse(File.read(File.join(FILES_DIR, filename)))
end

# ─── Van Gogh paintings (primary challenge) ───────────────────────────────────

RSpec.describe PaintingsExtractor, 'Van Gogh paintings' do
  let(:html)     { load_html('van-gogh-paintings.html') }
  let(:expected) { load_json('expected-array.json')['artworks'] }
  let(:results)  { described_class.new(html).extract }

  it 'returns an Array' do
    expect(results).to be_an(Array)
  end

  it 'extracts the correct number of artworks' do
    expect(results.length).to eq(expected.length)
  end

  it 'extracts all painting names in order' do
    expect(results.map { |a| a[:name] }).to eq(expected.map { |a| a['name'] })
  end

  it 'extracts extensions as an Array or nil for every artwork' do
    results.each do |artwork|
      ext = artwork[:extensions]
      expect([Array, NilClass]).to include(ext.class), "expected extensions to be Array or nil for #{artwork[:name]}"
    end
  end

  it 'matches the expected extensions' do
    results.each_with_index do |artwork, i|
      expect(artwork[:extensions]).to eq(expected[i]['extensions']),
        "extensions mismatch for #{artwork[:name]}"
    end
  end

  it 'extracts a full Google URL link for every artwork' do
    results.each do |artwork|
      expect(artwork[:link]).to be_a(String), "expected link to be String for #{artwork[:name]}"
      expect(artwork[:link]).to start_with('https://www.google.com')
    end
  end

  it 'matches the expected links' do
    results.each_with_index do |artwork, i|
      expect(artwork[:link]).to eq(expected[i]['link']),
        "link mismatch for #{artwork[:name]}"
    end
  end

  it 'includes images only for artworks that have embedded thumbnails' do
    # First 8 paintings have base64 thumbnails already in the HTML
    results.first(8).each do |artwork|
      expect(artwork[:image]).to be_a(String), "expected embedded image for #{artwork[:name]}"
      expect(artwork[:image]).to start_with('data:image/')
    end
  end

  it 'does not include images that would require extra HTTP requests' do
    # Items beyond the first 8 have data-src pointing to external URLs
    results.drop(8).each do |artwork|
      expect(artwork).not_to have_key(:image),
        "#{artwork[:name]} should not have an image (would require HTTP request)"
    end
  end

  it 'first artwork is The Starry Night' do
    expect(results.first[:name]).to eq('The Starry Night')
  end

  it 'first artwork image matches expected' do
    expect(results.first[:image]).to eq(expected.first['image'])
  end
end

# ─── Claude Monet paintings (additional layout test) ──────────────────────────

RSpec.describe PaintingsExtractor, 'Claude Monet paintings' do
  let(:html)    { load_html('claude-monet-paintings.html') }
  let(:results) { described_class.new(html).extract }

  before(:all) do
    path = File.join(FILES_DIR, 'claude-monet-paintings.html')
    skip 'claude-monet-paintings.html not found' unless File.exist?(path)
  end

  it 'returns a non-empty Array' do
    expect(results).to be_an(Array)
    expect(results).not_to be_empty
  end

  it 'extracts painting names as non-empty strings' do
    results.each do |artwork|
      expect(artwork[:name]).to be_a(String)
      expect(artwork[:name]).not_to be_empty
    end
  end

  it 'extracts extensions as Array or nil' do
    results.each do |artwork|
      ext = artwork[:extensions]
      expect([Array, NilClass]).to include(ext.class)
    end
  end

  it 'extracts Google links' do
    results.each do |artwork|
      expect(artwork[:link]).to be_a(String)
      expect(artwork[:link]).to start_with('https://www.google.com')
    end
  end

  it 'includes embedded thumbnails for the first 3 items' do
    results.first(3).each do |artwork|
      expect(artwork[:image]).to be_a(String)
      expect(artwork[:image]).to start_with('data:image/')
    end
  end
end

# ─── Rembrandt paintings (additional layout test) ─────────────────────────────

RSpec.describe PaintingsExtractor, 'Rembrandt paintings' do
  let(:html)    { load_html('rembrandt-paintings.html') }
  let(:results) { described_class.new(html).extract }

  before(:all) do
    path = File.join(FILES_DIR, 'rembrandt-paintings.html')
    skip 'rembrandt-paintings.html not found' unless File.exist?(path)
  end

  it 'returns a non-empty Array' do
    expect(results).to be_an(Array)
    expect(results).not_to be_empty
  end

  it 'extracts painting names as non-empty strings' do
    results.each do |artwork|
      expect(artwork[:name]).to be_a(String)
      expect(artwork[:name]).not_to be_empty
    end
  end

  it 'extracts extensions as Array or nil' do
    results.each do |artwork|
      ext = artwork[:extensions]
      expect([Array, NilClass]).to include(ext.class)
    end
  end

  it 'extracts Google links' do
    results.each do |artwork|
      expect(artwork[:link]).to be_a(String)
      expect(artwork[:link]).to start_with('https://www.google.com')
    end
  end

  it 'includes embedded thumbnails for the first 3 items' do
    results.first(3).each do |artwork|
      expect(artwork[:image]).to be_a(String)
      expect(artwork[:image]).to start_with('data:image/')
    end
  end

  it 'handles artworks with no year (nil extensions)' do
    no_year = results.find { |a| a[:extensions].nil? }
    expect(no_year).not_to be_nil, 'expected at least one artwork with nil extensions'
    expect(no_year[:name]).to eq("The Hundred Guilder Print")
  end
end
