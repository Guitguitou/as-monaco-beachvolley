namespace :balances do
  desc "Recalculer tous les soldes basés sur les transactions"
  task recalculate: :environment do
    puts "🔧 Recalcul des soldes utilisateurs"
    puts "=" * 50

    fixed_count = 0
    total_users = User.count

    User.includes(:balance, :credit_transactions).find_each do |user|
      next unless user.credit_transactions.any?

      # Calculer le solde basé sur les transactions
      calculated_balance = user.credit_transactions.sum(:amount)
      current_balance = user.balance&.amount || 0

      if calculated_balance != current_balance
        puts "👤 #{user.first_name} #{user.last_name}:"
        puts "  - Solde actuel: #{current_balance} crédits"
        puts "  - Solde calculé: #{calculated_balance} crédits"
        puts "  - Écart: #{calculated_balance - current_balance} crédits"

        # Créer ou mettre à jour le solde
        if user.balance
          user.balance.update!(amount: calculated_balance)
        else
          user.create_balance!(amount: calculated_balance)
        end

        puts "  ✅ Solde corrigé"
        fixed_count += 1
      end
    end

    puts ""
    puts "✅ Recalcul terminé"
    puts "📊 Utilisateurs corrigés: #{fixed_count}/#{total_users}"
  end

  desc "Vérifier la cohérence des soldes"
  task check: :environment do
    puts "🔍 Vérification de la cohérence des soldes"
    puts "=" * 50

    inconsistent_users = []

    User.includes(:balance, :credit_transactions).find_each do |user|
      next unless user.credit_transactions.any?

      calculated_balance = user.credit_transactions.sum(:amount)
      current_balance = user.balance&.amount || 0

      if calculated_balance != current_balance
        inconsistent_users << {
          user: user,
          current: current_balance,
          calculated: calculated_balance,
          diff: calculated_balance - current_balance
        }
      end
    end

    if inconsistent_users.any?
      puts "❌ #{inconsistent_users.count} utilisateurs avec des soldes incohérents:"
      inconsistent_users.each do |data|
        puts "  - #{data[:user].first_name} #{data[:user].last_name}: #{data[:current]} → #{data[:calculated]} (#{data[:diff] > 0 ? '+' : ''}#{data[:diff]})"
      end
    else
      puts "✅ Tous les soldes sont cohérents"
    end
  end
end
