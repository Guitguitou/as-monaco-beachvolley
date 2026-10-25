# frozen_string_literal: true

module UiKit
  # Données d'exemple du UI kit (/ui-kit).
  #
  # La page est publique : tout est construit en mémoire, rien n'est lu ni
  # écrit en base, pour n'exposer aucun vrai joueur et rendre la même page
  # dans tous les environnements.
  class Samples
    def player(first_name: "Alice", last_name: "Martin", id: 1, **attributes)
      User.new(id: id, first_name: first_name, last_name: last_name,
               email: "#{first_name.parameterize}@exemple.test", **attributes)
    end

    def activated_player
      player(activated_at: Date.new(2026, 9, 1), license_type: "competition", dossier_complet: true)
    end

    def pending_player
      player(activated_at: Date.new(2026, 9, 1), license_type: "libre", dossier_complet: false)
    end

    def guest_player
      player(activated_at: nil)
    end

    def coach
      player(first_name: "Marc", last_name: "Coach", id: 99, coach: true)
    end

    def ranked_players
      [
        { user: player(id: 1), name: "Alice", count: 18, rank: 1 },
        { user: player(first_name: "Bob", last_name: "Durand", id: 2), name: "Bob", count: 12, rank: 2 },
        { user: player(first_name: "Chloé", last_name: "Petit", id: 3), name: "Chloé", count: 9, rank: 3 },
        { user: player(first_name: "David", last_name: "Roux", id: 4), name: "David", count: 4, rank: 4 },
        { user: player(first_name: "Emma", last_name: "Blanc", id: 5), name: "Emma", count: 1, rank: 5 }
      ]
    end

    def terrain(position = 1)
      Terrain.new(id: position, name: "Terrain #{position}", position: position,
                  color: Terrains::Palette::KEYS[position - 1])
    end

    def session(session_type: "entrainement", terrain: self.terrain, **attributes)
      start_at = 2.days.from_now.change(hour: 18)
      Session.new(id: 1, title: "Entraînement confirmés", session_type: session_type, terrain: terrain,
                  start_at: start_at, end_at: start_at + 2.hours, max_players: 12, price: 10,
                  user: coach, **attributes)
    end

    def session_with_players
      session.tap do |s|
        ranked_players.each { |p| s.registrations.build(user: p[:user], status: :confirmed) }
      end
    end

    def card_state(registration: nil, confirmed_count: 5, **session_attributes)
      Sessions::CardState.new(session: session(**session_attributes), user: activated_player,
                              registration: registration, confirmed_count: confirmed_count,
                              conflict: false, balance: 100)
    end

    def registration
      session_with_players.registrations.build(user: activated_player, status: :confirmed)
    end

    def revenue_months
      [ [ 1, { "credits" => 100.0 } ], [ 2, { "credits" => 150.0, "licence" => 50.0 } ], [ 3, { "credits" => 120.0 } ] ]
        .map do |month, by_type|
          { period: I18n.l(Date.new(2026, month), format: :month_and_year), month: month, year: 2026,
            by_type: by_type.transform_values { |amount| { count: 1, amount: amount } }, total: by_type.values.sum }
        end
    end

    def player_spending
      stat = Reporting::PlayerSessionSpending::Stat
      totals = { "entrainement" => stat.new(count: 2, amount: 16.0) }
      Spending.new(rows: [ Reporting::PlayerSessionSpending::Row.new(user: player, by_type: totals) ],
                   session_types: %w[entrainement], totals: totals)
    end

    def spending_period
      Admin::SessionsPeriod.new("month", Date.current.strftime("%Y-%m"))
    end

    # Même interface que Reporting::PlayerSessionSpending, sans requête.
    Spending = Data.define(:rows, :session_types, :totals)
  end
end
