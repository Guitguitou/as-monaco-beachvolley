# frozen_string_literal: true

module Sessions
  # Utilisateurs qu'un gestionnaire peut ajouter à une session : pas encore
  # inscrits, du bon niveau pour un entraînement restreint, assez de crédits
  # hors coaching privé, et sans session confirmée qui chevauche — sauf si la
  # session est pleine, l'ajout partant alors en liste d'attente.
  class CandidateUsersQuery
    def self.call(session:)
      new(session).call
    end

    def initialize(session)
      @session = session
    end

    def call
      scope = User.where.not(id: @session.registrations.select(:user_id))
      scope = scope.joins(:user_levels).where(user_levels: { level_id: @session.level_ids }) if level_restricted?
      scope = scope.joins(:balance).where("balances.amount >= ?", @session.price) unless @session.coaching_prive?
      scope = scope.where.not(id: busy_user_ids) unless @session.full?
      scope.order(:first_name, :last_name).distinct
    end

    private

    def level_restricted?
      @session.entrainement? && @session.levels.any?
    end

    def busy_user_ids
      User.joins(:sessions_registered)
        .where("sessions.start_at < ? AND sessions.end_at > ?", @session.end_at, @session.start_at)
        .select(:id)
    end
  end
end
