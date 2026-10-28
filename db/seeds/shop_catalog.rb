# frozen_string_literal: true

# Catalogue de la boutique équipements, repris du bon de commande 2026-2027.
# Idempotent : relancer le script complète sans dupliquer.
#   bin/rails runner db/seeds/shop_catalog.rb

puts "\n👕 Catalogue de la boutique équipements..."

photos_dir = Rails.root.join("db/seeds/shop")
sizes = %w[6XS 5XS 4XS 3XS 2XS XS S M L XL 2XL 3XL 4XL]
range = ->(from, to) { sizes[sizes.index(from)..sizes.index(to)] }
hex = { "Rouge" => "#e21e22", "Blanc" => "#ffffff", "Noir" => "#232323" }

guides = {
  joma_h: [ "Joma homme et unisexe", "Tour de poitrine",
            "6XS ; 55–57 ; 4–5 ans\n5XS ; 58–61 ; 5–6 ans\n4XS ; 62–66 ; 7–8 ans\n3XS ; 67–72 ; 9–10 ans\n2XS ; 73–79 ; 11–12 ans\n" \
            "XS ; 80–87 ; 12–14 ans\nS ; 88–95\nM ; 96–105\nL ; 106–112\nXL ; 113–119\n2XL ; 119–124\n3XL ; 124–129\n4XL ; 130–135" ],
  joma_f: [ "Joma femme", "Tour de poitrine", "S ; 83–89\nM ; 90–94\nL ; 95–98\nXL ; 99–103\n2XL ; 104–109\n3XL ; 110–115\n4XL ; 116–121" ],
  nine_u: [ "Nine unisexe", "Tour de poitrine", "2XS ; 72–81\nXS ; 81–92\nS ; 92–96\nM ; 96–100\nL ; 100–104\nXL ; 104–110\n2XL ; 110–113" ],
  nine_f: [ "Nine femme", "Tour de poitrine", "S ; 84–88\nM ; 88–92\nL ; 92–96\nXL ; 96–100\n2XL ; 100–104" ],
  nine_u_hips: [ "Nine unisexe (bas)", "Tour de hanches", "2XS ; 76–84\nXS ; 84–92\nS ; 92–96\nM ; 96–100\nL ; 100–104\nXL ; 104–108\n2XL ; 108–112" ],
  nine_f_hips: [ "Nine femme (bas)", "Tour de hanches", "S ; 91–95\nM ; 95–99\nL ; 99–103\nXL ; 103–107\n2XL ; 107–111" ]
}.transform_values do |name, measure, rows|
  Shop::SizeGuide.find_or_create_by!(name: name) { |guide| guide.assign_attributes(measure_label: measure, rows_text: rows) }
end

joma_marking = "Logo du club au dos : blanc sur rouge ou noir, rouge sur blanc."
nine_marking = "Logo du club au dos et Sideline devant et derrière, en blanc."

catalog = [
  { name: "Pack Championship VIII", brand: "Joma", description: "Veste, pantalon et t-shirt assortis", marking: joma_marking,
    cuts: [ [ "Homme", 68, range.("6XS", "4XL"), :joma_h ], [ "Femme", 68, range.("2XS", "2XL"), :joma_f ] ],
    colors: { "Rouge" => "pack-rouge", "Blanc" => "pack-blanc" } },
  { name: "T-shirt Championship VIII", brand: "Joma", description: "T-shirt d'entraînement", marking: joma_marking,
    cuts: [ [ "Homme", 20, range.("6XS", "4XL"), :joma_h ], [ "Femme", 20, range.("2XS", "2XL"), :joma_f ] ],
    colors: { "Rouge" => "ts-rouge", "Blanc" => "ts-blanc" } },
  { name: "Sweat zippé Olympiada", brand: "Joma", description: "Veste à capuche", marking: joma_marking,
    cuts: [ [ "Unisexe", 33, range.("6XS", "2XL"), :joma_h ] ],
    colors: { "Noir" => "sweat-noir", "Blanc" => "sweat-blanc", "Rouge" => "sweat-rouge" } },
  { name: "Parka polaire Trivor II", brand: "Joma", description: "Parka doublée polaire", marking: joma_marking,
    cuts: [ [ "Homme", 49, range.("6XS", "3XL"), :joma_h ], [ "Femme", 49, range.("XS", "XL"), :joma_f ] ],
    colors: { "Noir" => "parka-noir" } },
  { name: "Sac training 2 filets", brand: "Joma", description: "Sac à dos avec filets à ballons",
    cuts: [ [ "Taille unique", 21, [ "Taille unique" ], nil ] ],
    colors: { "Noir" => "bag-noir", "Rouge" => "bag-rouge" } },
  { name: "Survêtement Campi", brand: "Nine", description: "Veste à capuche et bas à poches zippées", marking: nine_marking,
    cuts: [ [ "Unisexe", 58, range.("3XS", "3XL"), :nine_u ] ],
    colors: { "Noir" => "campi-noir" } },
  { name: "T-shirt Varone", brand: "Nine", description: "T-shirt d'entraînement", marking: nine_marking,
    cuts: [ [ "Homme", 18, range.("2XS", "3XL"), :nine_u ], [ "Femme", 18, range.("2XS", "2XL"), :nine_f ] ],
    colors: { "Rouge" => "varone-rouge", "Noir" => "varone-noir" } },
  { name: "Short d'entraînement", brand: "Nine", description: "Short technique",
    cuts: [ [ "Homme", 12, range.("2XS", "2XL"), :nine_u_hips ], [ "Femme", 14, range.("2XS", "2XL"), :nine_f_hips ] ],
    colors: { "Noir" => "short-h" } },
  { name: "Chaussettes pro volley", brand: "Nine", description: "Lot de 2 paires",
    cuts: [ [ "Basse", 12, %w[32–35 36–39 40–43 44–47 48–52], nil ], [ "Haute", 14, %w[36–39 40–43 44–47], nil ] ],
    colors: { "Blanc" => "socks-h" } }
]

catalog.each.with_index(1) do |entry, position|
  product = Shop::Product.find_or_create_by!(name: entry[:name]) do |record|
    record.assign_attributes(entry.slice(:brand, :description, :marking).merge(position: position))
  end

  entry[:cuts].each.with_index(1) do |(label, price, cut_sizes, guide), index|
    Shop::Cut.find_or_create_by!(product: product, label: label) do |cut|
      cut.assign_attributes(price_eur: price, sizes: cut_sizes, size_guide: guides[guide], position: index)
    end
  end

  entry[:colors].each.with_index(1) do |(name, photo), index|
    color = Shop::Color.find_or_create_by!(product: product, name: name) { |record| record.assign_attributes(hex: hex.fetch(name), position: index) }
    next if color.photo.attached?

    color.photo.attach(io: photos_dir.join("#{photo}.jpg").open, filename: "#{photo}.jpg", content_type: "image/jpeg")
  end
end

puts "✅ #{Shop::Product.count} articles, #{Shop::Cut.count} coupes, #{Shop::Color.count} coloris, #{Shop::SizeGuide.count} guides des tailles"
