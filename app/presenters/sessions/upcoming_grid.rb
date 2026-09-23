# frozen_string_literal: true

module Sessions
  # Données de la vue grille des sessions à venir pour un joueur : les sessions
  # où il est déjà inscrit, celles où il peut s'inscrire, et ce qu'il faut aux
  # cartes pour s'afficher sans requête par session.
  class UpcomingGrid
    def initialize(user:, sessions:)
      @user = user
      # `registrations: :user` alimente les avatars des inscrits sur les cartes.
      @sessions = sessions.includes(:levels, :user, registrations: :user).to_a
    end

    def registered
      @registered ||= @sessions.select { |session| registrations_by_session_id.key?(session.id) }
    end

    def eligible
      @eligible ||= (@sessions - registered).select { |session| eligible?(session) }
    end

    def registrations_by_session_id
      @registrations_by_session_id ||= @user.registrations.where(session_id: session_ids).index_by(&:session_id)
    end

    def confirmed_counts_by_session_id
      @confirmed_counts_by_session_id ||= Registration.confirmed.where(session_id: session_ids).group(:session_id).count
    end

    # Sessions qui chevauchent une session où le joueur est confirmé.
    def conflict_session_ids
      @conflict_session_ids ||= Session.where(id: session_ids)
        .where(Session.from("sessions AS booked").where(booked: { id: @user.sessions_registered.select(:id) })
          .where("booked.start_at < sessions.end_at AND booked.end_at > sessions.start_at").arel.exists)
        .pluck(:id)
    end

    # Priorité hebdomadaire : une seule requête pour toute la grille.
    def weekly_ranks_by_session_id
      @weekly_ranks_by_session_id ||= Registrations::UserWeeklyPriorityMap.call(user: @user, sessions: registered + eligible)
    end

    def user_level_ids
      @user_level_ids ||= @user.levels.pluck(:id)
    end

    def balance_amount
      @balance_amount ||= @user.balance&.amount.to_i
    end

    private

    def session_ids
      @sessions.map(&:id)
    end

    def eligible?(session)
      return false if session.coaching_prive?
      return false unless session.registration_open_state_for(@user).first
      return false unless level_allowed?(session)
      return false if full?(session)

      balance_amount >= session.price.to_i
    end

    def level_allowed?(session)
      !session.entrainement? || session.levels.empty? || (session.level_ids & user_level_ids).any?
    end

    def full?(session)
      session.max_players.present? && confirmed_counts_by_session_id[session.id].to_i >= session.max_players
    end
  end
end
