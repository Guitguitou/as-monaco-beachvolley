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

FactoryBot.define do
  factory :shop_campaign, class: "Shop::Campaign" do
    name { "Commande groupée 2026-2027" }
    opens_on { Date.current - 1 }
    closes_on { Date.current + 14 }
    status { "open" }
  end

  factory :shop_order, class: "Shop::Order" do
    association :user
    association :campaign, factory: :shop_campaign
    status { "cart" }
  end

  factory :shop_order_line, class: "Shop::OrderLine" do
    association :order, factory: :shop_order
    cut { association :shop_cut }
    product { cut.product }
    product_name { product.name }
    cut_label { cut.label }
    color_name { "Rouge" }
    size { "M" }
    quantity { 1 }
    unit_price_cents { cut.price_cents }
  end
end
