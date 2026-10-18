# frozen_string_literal: true

require "rails_helper"

RSpec.describe Avatars::Normalize do
  def photo(width:, height:)
    file = Tempfile.new([ "photo", ".png" ])
    MiniMagick::Tool::Convert.new do |convert|
      convert.size("#{width}x#{height}")
      convert << "xc:gray"
      convert << file.path
    end
    Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "Ma photo.png")
  end

  def dimensions(io)
    MiniMagick::Image.open(io.path).dimensions
  end

  it "réduit une grande photo à 1024 px au plus grand côté, en WebP" do
    result = described_class.new(photo(width: 3000, height: 2000)).call

    expect(dimensions(result[:io])).to eq([ 1024, 683 ])
    expect(MiniMagick::Image.open(result[:io].path).type).to eq("WEBP")
    expect(result).to include(filename: "Ma photo.webp", content_type: "image/webp")
  end

  it "n'agrandit pas une petite photo" do
    result = described_class.new(photo(width: 200, height: 100)).call

    expect(dimensions(result[:io])).to eq([ 200, 100 ])
  end

  it "rend tel quel un fichier qui n'est pas une image acceptée" do
    upload = Rack::Test::UploadedFile.new(Rails.root.join("Gemfile"), "text/plain")

    expect(described_class.new(upload).call).to be(upload)
  end
end
