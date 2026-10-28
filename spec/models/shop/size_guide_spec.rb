# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::SizeGuide do
  it "exige un nom, une mesure et au moins une ligne" do
    guide = build(:shop_size_guide, name: "", measure_label: "", rows: [])

    expect(guide).not_to be_valid
    expect(guide.errors.attribute_names).to include(:name, :measure_label, :rows)
  end

  it "lit et écrit le tableau sous forme de texte, une taille par ligne" do
    guide = build(:shop_size_guide, rows_text: "6XS ; 55–57 ; 4–5 ans\nS ; 88–95\n\n")

    expect(guide.rows).to eq([
      { "size" => "6XS", "measure" => "55–57", "note" => "4–5 ans" },
      { "size" => "S", "measure" => "88–95", "note" => "" }
    ])
    expect(guide.rows_text).to eq("6XS ; 55–57 ; 4–5 ans\nS ; 88–95")
  end
end
