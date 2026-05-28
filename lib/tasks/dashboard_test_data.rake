namespace :dashboard do
  desc "Ajouter des données de test pour le dashboard (production uniquement)"
  task add_test_data: :environment do
    if Rails.env.production?
      puts "🚨 ATTENTION: Vous êtes en production!"
      puts "Voulez-vous vraiment ajouter des données de test? (y/N)"
      response = STDIN.gets.chomp

      unless response.downcase == "y"
        puts "❌ Annulé"
        exit
      end
    end

    puts "📊 Ajout de données de test pour le dashboard..."

    # Vérifier s'il y a déjà des données
    if Session.count > 0
      puts "⚠️  Des sessions existent déjà (#{Session.count}). Voulez-vous continuer? (y/N)"
      response = STDIN.gets.chomp
      unless response.downcase == "y"
        puts "❌ Annulé"
        exit
      end
    end

    # Créer quelques sessions de test
    coaches = User.where(coach: true).limit(2)
    return puts "❌ Aucun coach trouvé" if coaches.empty?

    puts "🏐 Création de sessions de test..."

    # Sessions cette semaine
    3.times do |i|
      Session.create!(
        title: "Entraînement Test #{i + 1}",
        description: "Session de test pour le dashboard",
        start_at: (Time.current + (i + 1).days).change(hour: 18),
        end_at: (Time.current + (i + 1).days).change(hour: 20),
        session_type: "entrainement",
        user: coaches.sample,
        terrain: "Terrain 1",
        price: 400,
        max_players: 12,
        cancellation_deadline_at: (Time.current + (i + 1).days).change(hour: 16),
        registration_opens_at: (Time.current - 7.days).change(hour: 18)
      )
    end

    # Sessions de jeu libre
    2.times do |i|
      Session.create!(
        title: "Jeu Libre Test #{i + 1}",
        description: "Jeu libre de test",
        start_at: (Time.current + (i + 2).days).change(hour: 19),
        end_at: (Time.current + (i + 2).days).change(hour: 21),
        session_type: "jeu_libre",
        user: coaches.sample,
        terrain: "Terrain 2",
        price: 300,
        max_players: 16,
        cancellation_deadline_at: (Time.current + (i + 2).days).change(hour: 17),
        registration_opens_at: (Time.current - 7.days).change(hour: 19)
      )
    end

    # Créer quelques désinscriptions
    puts "📝 Création de désinscriptions de test..."
    sessions = Session.limit(3)
    users = User.where(admin: false, coach: false).limit(3)

    sessions.each_with_index do |session, index|
      user = users[index]
      next unless user

      LateCancellation.create!(
        user: user,
        session: session,
        created_at: (2 + index).days.ago
      )
    end

    puts "✅ Données de test ajoutées:"
    puts "  - Sessions: #{Session.count}"
    puts "  - Désinscriptions: #{LateCancellation.count}"
  end
end
