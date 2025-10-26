# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Création de packs de crédits par défaut
puts "Création des packs de crédits..."

Pack.find_or_create_by!(name: "Pack Découverte") do |pack|
  pack.description = "Idéal pour découvrir notre club"
  pack.pack_type = "credits"
  pack.amount_cents = 500  # 5 EUR
  pack.credits = 500
  pack.active = true
  pack.position = 1
end

Pack.find_or_create_by!(name: "Pack Standard") do |pack|
  pack.description = "Le pack le plus populaire"
  pack.pack_type = "credits"
  pack.amount_cents = 1000  # 10 EUR
  pack.credits = 1000
  pack.active = true
  pack.position = 2
end

Pack.find_or_create_by!(name: "Pack Premium") do |pack|
  pack.description = "Pour les joueurs réguliers - Meilleur rapport qualité/prix"
  pack.pack_type = "credits"
  pack.amount_cents = 2000  # 20 EUR
  pack.credits = 2200  # Bonus de 200 crédits
  pack.active = true
  pack.position = 3
end

Pack.find_or_create_by!(name: "Pack VIP") do |pack|
  pack.description = "Le maximum de crédits avec un super bonus"
  pack.pack_type = "credits"
  pack.amount_cents = 5000  # 50 EUR
  pack.credits = 6000  # Bonus de 1000 crédits
  pack.active = true
  pack.position = 4
end

puts "✅ #{Pack.count} packs créés"

# Création d'un stage de démonstration
puts "Création d'un stage de démonstration..."

stage = Stage.find_or_create_by!(title: "Stage Été 2025") do |s|
  s.description = "Stage de beach volley pour tous niveaux"
  s.starts_on = Date.current + 1.month
  s.ends_on = Date.current + 1.month + 1.week
  s.price_cents = 5000
end

# Création d'un pack de stage
puts "Création d'un pack de stage..."

Pack.find_or_create_by!(name: "Pack Stage Été") do |pack|
  pack.description = "Inscription au stage d'été avec hébergement"
  pack.pack_type = "stage"
  pack.amount_cents = 8000  # 80 EUR
  pack.stage_id = stage.id
  pack.active = true
  pack.position = 5
end

# Création d'un pack de licence
puts "Création d'un pack de licence..."

Pack.find_or_create_by!(name: "Licence Annuelle 2025") do |pack|
  pack.description = "Licence complète pour l'année 2025"
  pack.pack_type = "licence"
  pack.amount_cents = 15000  # 150 EUR
  pack.active = true
  pack.position = 6
end

puts "✅ #{Pack.count} packs au total (incluant stages et licences)"
