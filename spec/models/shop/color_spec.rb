# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::Color do
  it "exige un nom et une couleur hexadécimale" do
    color = build(:shop_color, name: "", hex: "rouge")

    expect(color).not_to be_valid
    expect(color.errors.attribute_names).to include(:name, :hex)
  end

  it "accepte une photo" do
    color = create(:shop_color)
    color.photo.attach(io: file_fixture("avatar.png").open, filename: "rouge.png", content_type: "image/png")

    expect(color.photo).to be_attached
  end
end
