# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Skip seeding in test environment to avoid interference with tests
return if Rails.env.test?

puts "🌱 Démarrage du seeding de l'application AS Monaco Beach Volley..."

# ===========================================
# 1. CRÉATION DES NIVEAUX
# ===========================================
puts "\n📊 Création des niveaux..."

levels_data = [
  { name: "Débutant", color: "#10B981", gender: "mixed" },
  { name: "G1", color: "#3B82F6", gender: "male" },
  { name: "G1", color: "#EC4899", gender: "female" },
  { name: "G2", color: "#8B5CF6", gender: "male" },
  { name: "G2", color: "#F59E0B", gender: "female" },
  { name: "G3", color: "#EF4444", gender: "male" },
  { name: "G3", color: "#06B6D4", gender: "female" },
  { name: "Expert", color: "#6B7280", gender: "mixed" }
]

levels_data.each do |level_data|
  Level.find_or_create_by!(name: level_data[:name], gender: level_data[:gender]) do |level|
    level.color = level_data[:color]
  end
end

puts "✅ #{Level.count} niveaux créés"

# ===========================================
# 2. CRÉATION DES UTILISATEURS
# ===========================================
puts "\n👥 Création des utilisateurs..."

# Admin principal
admin = User.find_or_create_by!(email: "admin@asmonaco-beachvolley.com") do |user|
  user.first_name = "Admin"
  user.last_name = "Principal"
  user.password = "password123"
  user.admin = true
  user.coach = true
  user.responsable = true
end

# Coachs
coach1 = User.find_or_create_by!(email: "coach1@asmonaco-beachvolley.com") do |user|
  user.first_name = "Marie"
  user.last_name = "Dubois"
  user.password = "password123"
  user.coach = true
  user.salary_per_training_cents = 5000  # 50€ par entraînement
end

coach2 = User.find_or_create_by!(email: "coach2@asmonaco-beachvolley.com") do |user|
  user.first_name = "Pierre"
  user.last_name = "Martin"
  user.password = "password123"
  user.coach = true
  user.salary_per_training_cents = 4500  # 45€ par entraînement
end

# Responsable
responsable = User.find_or_create_by!(email: "responsable@asmonaco-beachvolley.com") do |user|
  user.first_name = "Sophie"
  user.last_name = "Leroy"
  user.password = "password123"
  user.responsable = true
end

# Joueurs
players_data = [
  { first_name: "Alex", last_name: "Moreau", email: "alex.moreau@example.com" },
  { first_name: "Emma", last_name: "Bernard", email: "emma.bernard@example.com" },
  { first_name: "Lucas", last_name: "Petit", email: "lucas.petit@example.com" },
  { first_name: "Chloé", last_name: "Robert", email: "chloe.robert@example.com" },
  { first_name: "Thomas", last_name: "Richard", email: "thomas.richard@example.com" },
  { first_name: "Léa", last_name: "Durand", email: "lea.durand@example.com" },
  { first_name: "Hugo", last_name: "Moreau", email: "hugo.moreau@example.com" },
  { first_name: "Manon", last_name: "Simon", email: "manon.simon@example.com" }
]

players_data.each do |player_data|
  User.find_or_create_by!(email: player_data[:email]) do |user|
    user.first_name = player_data[:first_name]
    user.last_name = player_data[:last_name]
    user.password = "password123"
  end
end

puts "✅ #{User.count} utilisateurs créés"

# ===========================================
# 3. ASSIGNATION DES NIVEAUX AUX JOUEURS
# ===========================================
puts "\n🎯 Assignation des niveaux aux joueurs..."

players = User.where(admin: false, coach: false, responsable: false)
levels = Level.all

players.each_with_index do |player, index|
  # Assigner un niveau aléatoire à chaque joueur
  level = levels.sample
  UserLevel.find_or_create_by!(user: player, level: level)
end

puts "✅ Niveaux assignés aux joueurs"

# ===========================================
# 4. CRÉATION DES STAGES
# ===========================================
puts "\n🏖️ Création des stages..."

stages_data = [
  {
    title: "Stage Été 2025",
    description: "Stage de beach volley pour tous niveaux avec hébergement",
    starts_on: Date.current + 1.month,
    ends_on: Date.current + 1.month + 1.week,
    price_cents: 5000,  # 50€
    main_coach: coach1,
    assistant_coach: coach2
  },
  {
    title: "Stage Perfectionnement",
    description: "Stage intensif pour joueurs confirmés",
    starts_on: Date.current + 2.months,
    ends_on: Date.current + 2.months + 3.days,
    price_cents: 3000,  # 30€
    main_coach: coach2
  },
  {
    title: "Stage Débutants",
    description: "Découverte du beach volley pour les nouveaux",
    starts_on: Date.current + 3.months,
    ends_on: Date.current + 3.months + 2.days,
    price_cents: 2000,  # 20€
    main_coach: coach1
  }
]

stages_data.each do |stage_data|
  Stage.find_or_create_by!(title: stage_data[:title]) do |stage|
    stage.description = stage_data[:description]
    stage.starts_on = stage_data[:starts_on]
    stage.ends_on = stage_data[:ends_on]
    stage.price_cents = stage_data[:price_cents]
    stage.main_coach = stage_data[:main_coach]
    stage.assistant_coach = stage_data[:assistant_coach]
  end
end

puts "✅ #{Stage.count} stages créés"

# ===========================================
# 5. CRÉATION DES PACKS
# ===========================================
puts "\n📦 Création des packs..."

# Packs de crédits
credits_packs_data = [
  { name: "Pack Découverte", description: "Idéal pour découvrir notre club", amount_cents: 500, credits: 500, position: 1 },
  { name: "Pack Standard", description: "Le pack le plus populaire", amount_cents: 1000, credits: 1000, position: 2 },
  { name: "Pack Premium", description: "Pour les joueurs réguliers - Meilleur rapport qualité/prix", amount_cents: 2000, credits: 2200, position: 3 },
  { name: "Pack VIP", description: "Le maximum de crédits avec un super bonus", amount_cents: 5000, credits: 6000, position: 4 }
]

credits_packs_data.each do |pack_data|
  Pack.find_or_create_by!(name: pack_data[:name]) do |pack|
    pack.description = pack_data[:description]
    pack.pack_type = "credits"
    pack.amount_cents = pack_data[:amount_cents]
    pack.credits = pack_data[:credits]
    pack.active = true
    pack.position = pack_data[:position]
  end
end

# Packs de stages
stages = Stage.all
stages.each_with_index do |stage, index|
  Pack.find_or_create_by!(name: "Pack #{stage.title}") do |pack|
    pack.description = "Inscription au #{stage.title.downcase}"
    pack.pack_type = "stage"
    pack.amount_cents = stage.price_cents + 3000  # Prix du stage + 30€ de frais
    pack.stage_id = stage.id
    pack.active = true
    pack.position = 10 + index
  end
end

# Packs de licence
licence_packs_data = [
  { name: "Licence Annuelle 2025", description: "Licence complète pour l'année 2025", amount_cents: 15000, position: 20 },
  { name: "Licence Étudiante", description: "Licence à tarif réduit pour les étudiants", amount_cents: 10000, position: 21 }
]

licence_packs_data.each do |pack_data|
  Pack.find_or_create_by!(name: pack_data[:name]) do |pack|
    pack.description = pack_data[:description]
    pack.pack_type = "licence"
    pack.amount_cents = pack_data[:amount_cents]
    pack.active = true
    pack.position = pack_data[:position]
  end
end

puts "✅ #{Pack.count} packs créés"

# ===========================================
# 5.5. AJOUT DE CRÉDITS AUX COACHS
# ===========================================
puts "\n💰 Ajout de crédits aux coachs..."

# Ajouter des crédits aux coachs pour qu'ils puissent créer des sessions de coaching privé
[ coach1, coach2 ].each do |coach|
  CreditTransaction.create!(
    user: coach,
    amount: 5000,  # 5000 crédits pour créer des coachings privés
    transaction_type: "manual_adjustment"
  )
end

puts "✅ Crédits ajoutés aux coachs"

# ===========================================
# 6. CRÉATION DES SESSIONS
# ===========================================
puts "\n🏐 Création des sessions..."

# Sessions d'entraînement pour les 4 prochaines semaines
(0..3).each do |week|
  week_start = Date.current.beginning_of_week + week.weeks

  # Entraînements G1 Masculin (Lundi 18h-20h)
  Session.find_or_create_by!(
    title: "Entraînement G1 Masculin",
    start_at: week_start + 1.day + 18.hours,
    terrain: "Terrain 1"
  ) do |session|
    session.description = "Entraînement pour le niveau G1 masculin"
    session.end_at = session.start_at + 2.hours
    session.session_type = "entrainement"
    session.user = coach1
    session.max_players = 12
    session.registration_opens_at = session.start_at - 1.week
    session.cancellation_deadline_at = session.start_at - 2.hours
  end

  # Entraînements G1 Féminin (Mercredi 18h-20h)
  Session.find_or_create_by!(
    title: "Entraînement G1 Féminin",
    start_at: week_start + 3.days + 18.hours,
    terrain: "Terrain 2"
  ) do |session|
    session.description = "Entraînement pour le niveau G1 féminin"
    session.end_at = session.start_at + 2.hours
    session.session_type = "entrainement"
    session.user = coach2
    session.max_players = 12
    session.registration_opens_at = session.start_at - 1.week
    session.cancellation_deadline_at = session.start_at - 2.hours
  end

  # Jeu libre (Vendredi 19h-21h)
  Session.find_or_create_by!(
    title: "Jeu libre",
    start_at: week_start + 5.days + 19.hours,
    terrain: "Terrain 3"
  ) do |session|
    session.description = "Jeu libre ouvert à tous les niveaux"
    session.end_at = session.start_at + 2.hours
    session.session_type = "jeu_libre"
    session.user = coach1
    session.max_players = 16
    session.registration_opens_at = session.start_at - 3.days
    session.cancellation_deadline_at = session.start_at - 1.hour
  end

  # Tournoi (Samedi 14h-18h)
  Session.find_or_create_by!(
    title: "Tournoi du week-end",
    start_at: week_start + 6.days + 14.hours,
    terrain: "Terrain 1"
  ) do |session|
    session.description = "Tournoi amical du week-end"
    session.end_at = session.start_at + 4.hours
    session.session_type = "tournoi"
    session.user = coach1
    session.max_players = 8
    session.registration_opens_at = session.start_at - 1.week
    session.cancellation_deadline_at = session.start_at - 2.hours
  end
end

puts "✅ #{Session.count} sessions créées"

# ===========================================
# 7. ASSIGNATION DES NIVEAUX AUX SESSIONS
# ===========================================
puts "\n🎯 Assignation des niveaux aux sessions..."

Session.all.each do |session|
  case session.title
  when /G1 Masculin/
    g1_male = Level.find_by(name: "G1", gender: "male")
    SessionLevel.find_or_create_by!(session: session, level: g1_male) if g1_male
  when /G1 Féminin/
    g1_female = Level.find_by(name: "G1", gender: "female")
    SessionLevel.find_or_create_by!(session: session, level: g1_female) if g1_female
  when /Jeu libre/
    # Jeu libre ouvert à tous les niveaux
    Level.all.each do |level|
      SessionLevel.find_or_create_by!(session: session, level: level)
    end
  when /Tournoi/
    # Tournoi ouvert à tous les niveaux
    Level.all.each do |level|
      SessionLevel.find_or_create_by!(session: session, level: level)
    end
  end
end

puts "✅ Niveaux assignés aux sessions"

# ===========================================
# 8. CRÉATION DE QUELQUES INSCRIPTIONS
# ===========================================
puts "\n📝 Création d'inscriptions d'exemple..."

# Inscriptions pour les prochaines sessions
upcoming_sessions = Session.upcoming.limit(4)
players_with_credits = players.limit(6)

upcoming_sessions.each do |session|
  # Inscrire 3-5 joueurs par session
  selected_players = players_with_credits.sample(rand(3..5))

  selected_players.each do |player|
    # Vérifier que le joueur a le bon niveau pour la session
    player_levels = player.levels
    session_levels = session.levels

    if (player_levels & session_levels).any?
      Registration.find_or_create_by!(user: player, session: session) do |registration|
        registration.status = "confirmed"
        registration.registered_at = Time.current
      end
    end
  end
end

puts "✅ #{Registration.count} inscriptions créées"

# ===========================================
# 9. AJOUT DE CRÉDITS À QUELQUES JOUEURS
# ===========================================
puts "\n💰 Ajout de crédits aux joueurs..."

# Ajouter des crédits à quelques joueurs
players_with_credits.each do |player|
  # Ajouter entre 1000 et 3000 crédits
  credits_amount = rand(1000..3000)

  CreditTransaction.create!(
    user: player,
    amount: credits_amount,
    transaction_type: "manual_adjustment"
  )
end

puts "✅ Crédits ajoutés aux joueurs"

# ===========================================
# 10. RÉSUMÉ FINAL
# ===========================================
puts "\n🎉 Seeding terminé avec succès !"
puts "\n📊 Résumé des données créées :"
puts "   👥 #{User.count} utilisateurs (#{User.admins.count} admins, #{User.coachs.count} coachs, #{User.responsables.count} responsables)"
puts "   📊 #{Level.count} niveaux"
puts "   🏖️ #{Stage.count} stages"
puts "   📦 #{Pack.count} packs (#{Pack.credits_packs.count} crédits, #{Pack.stage_packs.count} stages, #{Pack.licence_packs.count} licences)"
puts "   🏐 #{Session.count} sessions"
puts "   📝 #{Registration.count} inscriptions"
puts "   💰 #{CreditTransaction.count} transactions de crédits"
puts "\n🔑 Comptes de test créés :"
puts "   👑 Admin: admin@asmonaco-beachvolley.com (password123)"
puts "   🏐 Coach 1: coach1@asmonaco-beachvolley.com (password123)"
puts "   🏐 Coach 2: coach2@asmonaco-beachvolley.com (password123)"
puts "   👤 Responsable: responsable@asmonaco-beachvolley.com (password123)"
puts "   👥 Joueurs: alex.moreau@example.com, emma.bernard@example.com, etc. (password123)"
puts "\n🚀 L'application est prête à être utilisée !"
