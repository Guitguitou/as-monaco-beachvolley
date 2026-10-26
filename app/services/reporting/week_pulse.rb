# frozen_string_literal: true

module Reporting
  # Les chiffres clés de la semaine en cours (lundi → dimanche), chacun comparé
  # à la semaine précédente : la première chose que le Staff lit en arrivant.
  class WeekPulse
    def initialize(now: Time.current)
      @week = now.all_week(:monday)
    end

    def metrics
      [
        metric(:sessions, "Séances tenues", "calendar-check") { |range| Session.held.where(start_at: range).count },
        metric(:registrations, "Inscriptions", "users") { |range| confirmed_registrations(range).count },
        metric(:fill_rate, "Remplissage", "gauge", unit: "%") { |range| fill_rate(range) },
        metric(:revenue, "Encaissé", "euro", unit: "€") { |range| CreditPurchase.paid_status.where(paid_at: range).sum(:amount_cents) / 100 },
        metric(:late_cancellations, "Désinscriptions tardives", "user-x", higher_is_better: false) do |range|
          LateCancellation.counted.where(created_at: range).count
        end
      ]
    end

    private

    def metric(key, label, icon, unit: nil, higher_is_better: true)
      Comparison.new(key: key, label: label, icon: icon, current: yield(@week), previous: yield(previous_week), unit: unit,
                     higher_is_better: higher_is_better)
    end

    def previous_week = (@week.begin - 1.week)..(@week.end - 1.week)

    def confirmed_registrations(range)
      Registration.confirmed.joins(:session).merge(Session.held).where(sessions: { start_at: range })
    end

    # Places occupées sur places offertes, pour les séances à capacité limitée.
    def fill_rate(range)
      sessions = Session.held.where(start_at: range).where.not(max_players: nil)
      capacity = sessions.sum(:max_players)
      return 0 if capacity.zero?

      (confirmed_registrations(range).where(session_id: sessions.select(:id)).count * 100.0 / capacity).round
    end
  end
end
