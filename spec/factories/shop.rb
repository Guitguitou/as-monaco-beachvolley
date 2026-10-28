FactoryBot.define do
  factory :shop_size_guide, class: "Shop::SizeGuide" do
    name { "Joma homme" }
    measure_label { "Tour de poitrine" }
    rows { [ { "size" => "S", "measure" => "88–95", "note" => "" }, { "size" => "M", "measure" => "96–105", "note" => "" } ] }
  end

  factory :shop_product, class: "Shop::Product" do
    sequence(:name) { |n| "T-shirt Varone #{n}" }
    brand { "Nine" }
    description { "T-shirt d'entraînement" }
    active { true }
  end

  factory :shop_cut, class: "Shop::Cut" do
    association :product, factory: :shop_product
    label { "Homme" }
    price_cents { 1800 }
    sizes { %w[S M L] }
  end

  factory :shop_color, class: "Shop::Color" do
    association :product, factory: :shop_product
    name { "Rouge" }
    hex { "#e21e22" }
  end
end
