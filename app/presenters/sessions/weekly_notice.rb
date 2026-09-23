# frozen_string_literal: true

module Sessions
  # Signale sur une carte d'entraînement que le joueur en a déjà un plus ancien
  # cette semaine : il passe derrière ceux qui n'en ont pas encore. Jamais
  # bloquant, seulement signalé.
  class WeeklyNotice
    MESSAGES = {
      confirmed: "Tu as déjà un entraînement cette semaine : si un joueur prioritaire s'inscrit, tu repasses en liste d'attente (crédits rendus).",
      waitlisted: "Tu as déjà un entraînement cette semaine : tu passes après les joueurs qui n'en ont pas encore.",
      none: "Ce serait ton 2e entraînement de la semaine : tu passes après les joueurs qui n'en ont pas encore."
    }.freeze

    def initialize(session:, rank:, registration:)
      @session = session
      @rank = rank
      @status = registration&.status&.to_sym || :none
    end

    def secondary?
      @session.entrainement? && @rank.to_i == Registrations::WeeklyPriorityRule::SECONDARY
    end

    def badge_label
      @status == :none ? "2e entraînement" : "Non prioritaire"
    end

    def message
      MESSAGES.fetch(@status) if secondary?
    end
  end
end
