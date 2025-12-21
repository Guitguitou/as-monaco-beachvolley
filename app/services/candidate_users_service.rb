# frozen_string_literal: true

# Service pour trouver les utilisateurs candidats pour une session
# Extrait la logique métier depuis SessionsController#show
class CandidateUsersService
  def initialize(session)
    @session = session
  end

  def call
    base = User.where.not(id: registered_user_ids)

    base = apply_level_filter(base) if @session.entrainement? && @session.levels.any?
    base = apply_credits_filter(base) unless @session.coaching_prive?
    base = apply_schedule_conflict_filter(base) unless @session.full?

    base.order(:first_name, :last_name).distinct
  end

  private

  def registered_user_ids
    @session.registrations.pluck(:user_id)
  end

  def apply_level_filter(base)
    base.joins(:user_levels).where(user_levels: { level_id: @session.level_ids }).distinct
  end

  def apply_credits_filter(base)
    base.joins(:balance).where("balances.amount >= ?", @session.price)
  end

  def apply_schedule_conflict_filter(base)
    base.where.not(
      id: User
            .joins(:sessions_registered)
            .where("sessions.start_at < ? AND sessions.end_at > ?", @session.end_at, @session.start_at)
            .select(:id)
    )
  end
end
