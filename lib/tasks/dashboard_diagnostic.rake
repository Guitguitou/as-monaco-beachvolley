namespace :dashboard do
  desc "Diagnostic du dashboard admin"
  task diagnostic: :environment do
    puts "🔍 Diagnostic du Dashboard Admin"
    puts "=" * 50
    
    # 1. Vérifier l'environnement
    puts "📊 Environnement: #{Rails.env}"
    puts "📊 Cache store: #{Rails.cache.class.name}"
    
    # 2. Vérifier Redis si utilisé
    if Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
      begin
        Rails.cache.write("test_key", "test_value", expires_in: 1.minute)
        test_value = Rails.cache.read("test_key")
        if test_value == "test_value"
          puts "✅ Redis cache: OK"
        else
          puts "❌ Redis cache: Échec de lecture"
        end
      rescue => e
        puts "❌ Redis cache: Erreur - #{e.message}"
      end
    end
    
    # 3. Vérifier les données
    puts "\n📊 Données:"
    puts "  Sessions: #{Session.count}"
    puts "  Sessions par type: #{Session.group(:session_type).count}"
    puts "  Désinscriptions: #{LateCancellation.count}"
    puts "  Utilisateurs: #{User.count}"
    puts "  Coachs: #{User.where(coach: true).count}"
    
    # 4. Vérifier les services de reporting
    puts "\n🔧 Services de reporting:"
    begin
      kpis_service = Reporting::Kpis.new
      kpis = kpis_service.week_kpis
      puts "  ✅ Reporting::Kpis: OK"
      puts "    - Entraînements: #{kpis[:trainings_count]}"
      puts "    - Jeux libres: #{kpis[:free_plays_count]}"
      puts "    - Désinscriptions: #{kpis[:late_cancellations_count]}"
    rescue => e
      puts "  ❌ Reporting::Kpis: Erreur - #{e.message}"
    end
    
    begin
      coach_service = Reporting::CoachSalaries.new
      coach_breakdown = coach_service.breakdown(
        week_range: 1.week.ago..Time.current,
        month_range: 1.month.ago..Time.current,
        year_range: 1.year.ago..Time.current
      )
      puts "  ✅ Reporting::CoachSalaries: OK"
      puts "    - Coachs trouvés: #{coach_breakdown.count}"
    rescue => e
      puts "  ❌ Reporting::CoachSalaries: Erreur - #{e.message}"
    end
    
    # 5. Vérifier les plages de dates
    puts "\n📅 Plages de dates:"
    current_time = Time.current.in_time_zone('Europe/Paris')
    week_start = current_time.beginning_of_week(:monday)
    week_range = week_start..week_start.end_of_week(:monday)
    puts "  Semaine: #{week_range}"
    puts "  Sessions cette semaine: #{Session.where(start_at: week_range).count}"
    
    puts "\n✅ Diagnostic terminé"
  end
end
