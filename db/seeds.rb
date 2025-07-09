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
Level.find_or_create_by!(name: "Débutant") do |level|
  level.gender = "mixed"
  level.color = "#10B981" # Vert
end

Level.find_or_create_by!(name: "Intermédiaire") do |level|
  level.gender = "mixed"
  level.color = "#F59E0B" # Orange
end

Level.find_or_create_by!(name: "Avancé") do |level|
  level.gender = "mixed"
  level.color = "#EF4444" # Rouge
end

Level.find_or_create_by!(name: "Expert") do |level|
  level.gender = "mixed"
  level.color = "#8B5CF6" # Violet
end
