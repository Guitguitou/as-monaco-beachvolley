# frozen_string_literal: true

class DuplicateSessionService
  attr_reader :session, :weeks, :errors, :created_sessions

  def initialize(session, weeks = 1)
    @session = session
    @weeks = validate_weeks(weeks)
    @errors = []
    @created_sessions = []
  end

  def call
    return failure_result unless valid?

    (1..@weeks).each do |week_number|
      duplicate_session(week_number)
    end

    success? ? success_result : failure_result
  end

  def success?
    @errors.empty?
  end

  private

  def validate_weeks(weeks)
    weeks = weeks.to_i
    return 1 if weeks < 1
    return 20 if weeks > 20
    weeks
  end

  def valid?
    return false unless @session.present?
    return false unless @session.persisted?
    true
  end

  def duplicate_session(week_number)
    shift = week_number.weeks

    duplicated_session = @session.dup
    duplicated_session.assign_attributes(
      start_at: @session.start_at + shift,
      end_at: @session.end_at + shift,
      cancellation_deadline_at: @session.cancellation_deadline_at&.+(shift),
      registration_opens_at: @session.registration_opens_at&.+(shift)
    )

    # Clear registrations and participants
    duplicated_session.registrations = []

    # Copy level associations
    duplicated_session.level_ids = @session.level_ids

    begin
      if duplicated_session.save
        @created_sessions << duplicated_session
      else
        @errors << "Semaine #{week_number}: #{duplicated_session.errors.full_messages.to_sentence}"
      end
    rescue StandardError => e
      @errors << "Semaine #{week_number}: #{e.message}"
    end
  end

  def success_result
    {
      success: true,
      created_count: @created_sessions.count,
      created_sessions: @created_sessions,
      errors: []
    }
  end

  def failure_result
    {
      success: false,
      created_count: @created_sessions.count,
      created_sessions: @created_sessions,
      errors: @errors
    }
  end
end
