# frozen_string_literal: true

namespace :notifications do
  desc "Create default notification rules"
  task create_default_rules: :environment do
    rules = [
      {
        name: "Passage en liste principale",
        event_type: "waitlist_promoted",
        title_template: "Tu passes en liste principale !",
        body_template: "Quelqu'un s'est désinscrit de la session {{session_name}} du {{session_date}} à {{session_time}}, tu viens de passer en liste principale",
        enabled: true
      },
      {
        name: "Pas assez de crédits pour passer en liste principale",
        event_type: "waitlist_insufficient_credits",
        title_template: "Pas assez de crédits",
        body_template: "Tu n'as pas assez de crédits pour passer en liste principale.",
        enabled: true
      },
      {
        name: "Crédits faibles",
        event_type: "credit_low",
        title_template: "Crédits faibles",
        body_template: "Attention tu as moins de 500 crédits, pense à recharger 😉",
        enabled: true
      },
      {
        name: "Session annulée",
        event_type: "session_cancelled",
        title_template: "Session annulée",
        body_template: "La session {{session_name}} du {{session_date}} est annulée",
        enabled: true
      }
    ]

    rules.each do |rule_data|
      rule = NotificationRule.find_or_initialize_by(event_type: rule_data[:event_type])
      rule.assign_attributes(rule_data)
      if rule.save
        puts "✅ Règle créée/mise à jour : #{rule.name}"
      else
        puts "❌ Erreur pour #{rule_data[:name]}: #{rule.errors.full_messages.join(', ')}"
      end
    end

    puts "\n✅ Toutes les règles de notification ont été créées !"
  end
end
