# frozen_string_literal: true

class PlayerSuggestionsService
  DEFAULT_LIMIT = 5

  def initialize(user)
    @user = user
  end

  def summary(limit: DEFAULT_LIMIT)
    {
      players: suggested_players(limit: limit),
      open_sessions: suggested_open_sessions(limit: limit)
    }
  end

  def badge_count
    player_matches_count + pending_requests_count + open_sessions_count
  end

  def suggested_players(limit: DEFAULT_LIMIT)
    PlayerMatchingService.new(@user).matches.first(limit)
  end

  def suggested_open_sessions(limit: DEFAULT_LIMIT)
    open_sessions = Session.open_for_matching_upcoming.includes(:levels, :participants)
    filtered = open_sessions.select { |session| session_relevant?(session) }
    filtered.first(limit)
  end

  def session_relevant?(session)
    return false if session.blank?
    return false if !session.open_for_matching? || session.start_at.blank? || session.end_at.blank?
    return false if registered_to_session?(session)
    return false if session.full?

    open, = session.registration_open_state_for(@user)
    return false unless open

    return true unless active_listings.any?

    active_listings.any? { |listing| listing_matches_session?(listing, session) }
  end

  private

  def active_listings
    @active_listings ||= @user.player_listings.active.includes(:levels, :session)
  end

  def registered_to_session?(session)
    session.participants.any? { |participant| participant.id == @user.id }
  end

  def listing_matches_session?(listing, session)
    start_a = listing.effective_start_at
    end_a = listing.effective_end_at
    start_b = session.start_at
    end_b = session.end_at

    return false if start_a.blank? || end_a.blank? || start_b.blank? || end_b.blank?
    return false unless start_a < end_b && end_a > start_b

    listing_level_ids = listing.effective_level_ids
    session_level_ids = session.level_ids
    return true if listing_level_ids.empty? || session_level_ids.empty?

    (listing_level_ids & session_level_ids).any?
  end

  def player_matches_count
    PlayerMatchingService.new(@user).matches.count
  end

  def pending_requests_count
    PlayerRequest.pending.where(to_user: @user).count
  end

  def open_sessions_count
    Session.open_for_matching_upcoming.includes(:levels, :participants).count do |session|
      session_relevant?(session)
    end
  end
end
