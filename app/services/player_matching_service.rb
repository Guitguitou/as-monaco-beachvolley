class PlayerMatchingService
  def initialize(user)
    @user = user
  end

  def matches
    listings = active_listings_for_user
    return PlayerListing.none if listings.empty?

    candidates = PlayerListing.active.where.not(user_id: @user.id).includes(:levels, :session, :user)
    matched = listings.flat_map { |listing| matches_for(listing, candidates) }
    matched.uniq
  end

  def badge_count
    matches.size + pending_requests_count
  end

  def pending_requests_count
    PlayerRequest.pending.where(to_user: @user).count
  end

  def matches_for(listing, candidates)
    candidates.select { |candidate| match_between?(listing, candidate) }
  end

  def match_between?(listing, candidate)
    listing.listing_type != candidate.listing_type &&
      time_overlap?(listing, candidate) &&
      gender_compatible?(listing, candidate) &&
      level_compatible?(listing, candidate)
  end

  private

  def active_listings_for_user
    @user.player_listings.active.includes(:levels, :session)
  end

  def time_overlap?(listing, candidate)
    start_a = listing.effective_start_at
    end_a = listing.effective_end_at
    start_b = candidate.effective_start_at
    end_b = candidate.effective_end_at

    return false if start_a.blank? || end_a.blank? || start_b.blank? || end_b.blank?

    start_a < end_b && end_a > start_b
  end

  def gender_compatible?(listing, candidate)
    return true if listing.gender.blank? || candidate.gender.blank?
    return true if listing.gender == "mixed" || candidate.gender == "mixed"

    listing.gender == candidate.gender
  end

  def level_compatible?(listing, candidate)
    levels_a = listing.effective_level_ids
    levels_b = candidate.effective_level_ids
    return true if levels_a.empty? || levels_b.empty?

    (levels_a & levels_b).any?
  end
end
