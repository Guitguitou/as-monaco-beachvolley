# frozen_string_literal: true

module Sessions
  # État affichable d'une carte de session pour un joueur donné.
  #
  # La grille en affiche des dizaines : elle injecte les valeurs qu'elle a déjà
  # préchargées en une requête (inscription, compteur, conflit, solde) pour
  # éviter les N+1. Le rafraîchissement Turbo Stream d'une seule carte passe par
  # `.build`, qui calcule tout lui-même.
  class CardState
    ACCENTS = {
      "entrainement" => :training,
      "jeu_libre" => :free_play,
      "coaching_prive" => :private_coaching,
      "tournoi" => :tournament,
      "stage" => :stage
    }.freeze

    # Calcule l'état d'une seule session (hors grille, donc N+1 sans importance).
    def self.build(session:, user:)
      confirmed = session.registrations.select(&:confirmed?)

      new(
        session: session,
        user: user,
        registration: user && session.registrations.find { |r| r.user_id == user.id },
        confirmed_count: confirmed.size,
        conflict: user.present? && Registrations::ScheduleConflictQuery.call(user: user, session: session).exists?,
        balance: user&.balance&.amount.to_i
      )
    end

    def initialize(session:, user:, registration:, confirmed_count:, conflict:, balance:, user_level_ids: nil)
      @session = session
      @user = user
      @registration = registration
      @confirmed_count = confirmed_count.to_i
      @conflict = conflict
      @balance = balance.to_i
      @user_level_ids = user_level_ids || Array(user&.levels&.map(&:id))
    end

    attr_reader :session, :registration, :confirmed_count, :balance

    def accent
      ACCENTS[session.session_type]
    end

    def registered?
      registration&.confirmed?
    end

    def waitlisted?
      registration&.waitlisted?
    end

    def full?
      session.max_players.present? && confirmed_count >= session.max_players.to_i
    end

    def conflict?
      !registered? && !waitlisted? && @conflict
    end

    # Une session d'entraînement hors des groupes du joueur reste visible mais
    # signalée : elle ne lui est pas destinée en priorité.
    def off_level?
      return false unless session.entrainement?
      return false if session.levels.empty?

      (session.level_ids & @user_level_ids).empty?
    end

    def not_enough_credits?
      return false if session.coaching_prive?
      return false if registered? || waitlisted?

      balance < session.price.to_i
    end

    def open_state
      @open_state ||= session.registration_open_state_for(@user)
    end

    def open?
      open_state.first
    end

    def closed_reason
      open_state.last
    end

    # L'action unique proposée sur la carte.
    # :unregister, :leave_waitlist, :register, :waitlist ou :blocked
    def action
      return :leave_waitlist if waitlisted?
      return :unregister if registered?
      return :blocked unless actionable?
      return :waitlist if full?

      :register
    end

    def actionable?
      return false if @user.blank?
      return false unless open?
      return false if conflict?
      return false if not_enough_credits?

      true
    end

    # Pourquoi l'action est indisponible — le premier obstacle rencontré.
    def blocked_reason
      return "Connecte-toi pour t'inscrire" if @user.blank?
      return closed_reason unless open?
      return "Déjà une session sur ce créneau" if conflict?
      return "Crédits insuffisants" if not_enough_credits?

      nil
    end

    def action_label
      case action
      when :unregister then "Je me désinscris"
      when :leave_waitlist then "Quitter la liste d'attente"
      when :waitlist then "Rejoindre la liste d'attente"
      when :register then "Je m'inscris"
      else blocked_reason
      end
    end

    def destructive_action?
      action == :unregister || action == :leave_waitlist
    end

    # Participants confirmés, pour les avatars. Trié pour un rendu stable.
    def confirmed_participants
      @confirmed_participants ||= session.registrations
        .select(&:confirmed?)
        .sort_by { |r| r.created_at || Time.current }
        .map(&:user)
        .compact
    end
  end
end
