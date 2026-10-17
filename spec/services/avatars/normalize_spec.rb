# frozen_string_literal: true

require "rails_helper"

RSpec.describe Avatars::Normalize do
  def photo(width:, height:)
    file = Tempfile.new([ "photo", ".png" ])
    Vips::Image.black(width, height).add(120).cast(:uchar).write_to_file(file.path)
    Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "Ma photo.png")
  end

  it "réduit une grande photo à 1024 px au plus grand côté, en WebP" do
    result = described_class.new(photo(width: 3000, height: 2000)).call
    image = Vips::Image.new_from_file(result[:io].path)

    expect([ image.width, image.height ]).to eq([ 1024, 683 ])
    expect(result).to include(filename: "Ma photo.webp", content_type: "image/webp")
  end

  it "n'agrandit pas une petite photo" do
    result = described_class.new(photo(width: 200, height: 100)).call

    expect(Vips::Image.new_from_file(result[:io].path).width).to eq(200)
  end

  it "rend tel quel un fichier qui n'est pas une image acceptée" do
    upload = Rack::Test::UploadedFile.new(Rails.root.join("Gemfile"), "text/plain")

    expect(described_class.new(upload).call).to be(upload)
  end
end
