class DuplicateSessionService
  attr_reader :session, :weeks, :errors, :created_sessions

  def initialize(session, weeks = 1)
    @session = session
    @weeks = weeks.to_i.clamp(1, 20)
    @errors = []
    @created_sessions = []
  end

  def call
    return result(success: false) unless @session&.persisted?

    ensure_series_id

    (1..@weeks).each do |week_number|
      duplicate_session(week_number)
    end

    result(success: success?)
  end

  def success?
    @errors.empty?
  end

  private

  # Garantit que la session source appartient à une série. Les duplicats
  # reprendront ce même series_id afin de rester liés entre eux.
  def ensure_series_id
    return if @session.series_id.present?

    @session.update_column(:series_id, SecureRandom.uuid)
  end

  def duplicate_session(week_number)
    duplicated_session = shifted_copy(week_number.weeks)
    if duplicated_session.save
      # Copy the priority rank of each group (level_ids= recreates them at rank 0)
      duplicated_session.sync_level_priorities(@session.session_levels.pluck(:level_id, :priority).to_h)
      @created_sessions << duplicated_session
    else
      @errors << "Semaine #{week_number}: #{duplicated_session.errors.full_messages.to_sentence}"
    end
  rescue StandardError => e
    @errors << "Semaine #{week_number}: #{e.message}"
  end

  # Copie sans inscrits, mêmes groupes, toutes les dates décalées de `shift`.
  def shifted_copy(shift)
    copy = @session.dup
    copy.assign_attributes(
      start_at: @session.start_at + shift, end_at: @session.end_at + shift,
      cancellation_deadline_at: @session.cancellation_deadline_at&.+(shift),
      registration_opens_at: @session.registration_opens_at&.+(shift),
      series_id: @session.series_id, registrations: [], level_ids: @session.level_ids
    )
    copy
  end

  def result(success:)
    { success: success, created_count: @created_sessions.count, created_sessions: @created_sessions, errors: @errors }
  end
end
