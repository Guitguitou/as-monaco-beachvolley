# frozen_string_literal: true

module Sessions
  # L'action unique proposée sur une carte de session : se désinscrire, quitter
  # la liste d'attente, s'inscrire, rejoindre la liste d'attente, ou rien —
  # avec alors le premier obstacle rencontré comme libellé.
  class CardAction
    LABELS = {
      unregister: "Je me désinscris",
      leave_waitlist: "Quitter la liste d'attente",
      waitlist: "Rejoindre la liste d'attente",
      register: "Je m'inscris"
    }.freeze

    def initialize(signed_in:, registered:, waitlisted:, full:, open:, closed_reason:, conflict:, not_enough_credits:)
      @signed_in = signed_in
      @registered = registered
      @waitlisted = waitlisted
      @full = full
      @open = open
      @closed_reason = closed_reason
      @conflict = conflict
      @not_enough_credits = not_enough_credits
    end

    # :unregister, :leave_waitlist, :register, :waitlist ou :blocked
    def name
      return :leave_waitlist if @waitlisted
      return :unregister if @registered
      return :blocked unless actionable?

      @full ? :waitlist : :register
    end

    def actionable?
      blocked_reason.nil?
    end

    def blocked_reason
      return "Connecte-toi pour t'inscrire" unless @signed_in
      return @closed_reason unless @open
      return "Déjà une session sur ce créneau" if @conflict

      "Crédits insuffisants" if @not_enough_credits
    end

    def label
      LABELS.fetch(name) { blocked_reason }
    end

    def destructive?
      %i[unregister leave_waitlist].include?(name)
    end
  end
end
