# frozen_string_literal: true

module Reporting
  # Fréquentation d'une saison : participations par type de séance et par
  # mois, remplissage, et totaux comparés à la saison précédente à date égale.
  class SeasonAttendance
    TYPES = %w[entrainement jeu_libre coaching_prive stage].freeze

    def initialize(months)
      @months = months
    end

    def comparisons
      compare = SeasonComparisons.new(self, self.class.new(@months.previous))
      [
        compare.compare(:participations, "Participations", "users") { |report| report.participations.count },
        compare.compare(:players, "Joueurs différents", "user-check") { |report| report.participations.distinct.count(:user_id) },
        compare.compare(:sessions, "Séances tenues", "calendar-check") { |report| report.sessions.count },
        compare.compare(:fill_rate, "Remplissage", "gauge", unit: "%", &:fill_rate)
      ]
    end

    # Séries Chartkick des participations, une par type de séance.
    def participations_by_type
      counts = @months.group(participations, "sessions.start_at", by: "sessions.session_type")
      TYPES.map { |type| { name: ::Sessions::SessionType.for(type).label, data: @months.series_for(counts, type) } }
    end

    # Remplissage moyen par mois (places occupées / places offertes), en %.
    def fill_rate_by_month
      taken = @months.group(participations.where(session_id: limited_sessions.select(:id)), "sessions.start_at")
      offered = @months.group(limited_sessions, "sessions.start_at") { |grouped| grouped.sum(:max_players) }
      @months.series(offered.to_h { |(month), places| [ month, places.zero? ? 0 : (taken.fetch([ month ], 0) * 100.0 / places).round ] })
    end

    def participations = Registration.confirmed.joins(:session).merge(sessions)

    def sessions = Session.held.where(start_at: @months.range)

    def fill_rate
      places = limited_sessions.sum(:max_players)
      places.zero? ? 0 : (participations.where(session_id: limited_sessions.select(:id)).count * 100.0 / places).round
    end

    private

    def limited_sessions = sessions.where.not(max_players: [ nil, 0 ])
  end
end
