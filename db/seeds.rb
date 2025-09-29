# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

User.create(email: "admin@example.com", password: "password", admin: true)

# Créer des niveaux de base
Level.find_or_create_by!(name: "G1") do |level|
  level.gender = "mixed"
  level.color = "#10B981" # Vert
end

Level.find_or_create_by!(name: "G2") do |level|
  level.gender = "mixed"
  level.color = "#F59E0B" # Orange
end

Level.find_or_create_by!(name: "G3") do |level|
  level.gender = "mixed"
  level.color = "#EF4444" # Rouge
end

Level.find_or_create_by!(name: "G4") do |level|
  level.gender = "mixed"
  level.color = "#8B5CF6" # Violet
end

Level.find_or_create_by!(name: "G1") do |level|
  level.gender = "female"
  level.color = "#10B981" # Vert
end

Level.find_or_create_by!(name: "G2") do |level|
  level.gender = "female"
  level.color = "#F59E0B" # Orange
end

Level.find_or_create_by!(name: "G3") do |level|
  level.gender = "female"
  level.color = "#EF4444" # Rouge
end

Level.find_or_create_by!(name: "G4") do |level|
  level.gender = "female"
  level.color = "#8B5CF6" # Violet
end

Level.find_or_create_by!(name: "G1") do |level|
  level.gender = "male"
  level.color = "#10B981" # Vert
end

Level.find_or_create_by!(name: "G2") do |level|
  level.gender = "male"
  level.color = "#F59E0B" # Orange
end

Level.find_or_create_by!(name: "G3") do |level|
  level.gender = "male"
  level.color = "#EF4444" # Rouge
end

Level.find_or_create_by!(name: "G4") do |level|
  level.gender = "male"
  level.color = "#8B5CF6" # Violet
end

# Créer des forfaits de crédits d'exemple
CreditPackage.find_or_create_by!(name: "Forfait Débutant") do |package|
  package.description = "Parfait pour commencer le beach volley"
  package.credits = 500
  package.price_cents = 500 # 5€
  package.active = true
end

CreditPackage.find_or_create_by!(name: "Forfait Standard") do |package|
  package.description = "Le plus populaire pour une saison complète"
  package.credits = 1000
  package.price_cents = 1000 # 10€
  package.active = true
end

CreditPackage.find_or_create_by!(name: "Forfait Premium") do |package|
  package.description = "Pour les joueurs les plus assidus"
  package.credits = 2000
  package.price_cents = 1800 # 18€ (10% de réduction)
  package.active = true
end

CreditPackage.find_or_create_by!(name: "Forfait Pro") do |package|
  package.description = "Le meilleur rapport qualité-prix"
  package.credits = 5000
  package.price_cents = 4000 # 40€ (20% de réduction)
  package.active = true
end
