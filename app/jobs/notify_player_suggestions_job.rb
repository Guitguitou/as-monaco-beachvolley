# frozen_string_literal: true

class NotifyPlayerSuggestionsJob < ApplicationJob
  queue_as :default

  def perform(event_type:, listing_id: nil, session_id: nil)
    case event_type
    when "listing_created"
      notify_listing_created(listing_id)
    when "session_opened", "session_spot_released"
      notify_session_event(event_type, session_id)
    end
  end

  private

  def notify_listing_created(listing_id)
    listing = PlayerListing.active.find_by(id: listing_id)
    return if listing.blank?

    matcher = PlayerMatchingService.new(listing.user)
    candidates = PlayerListing.active.where.not(user_id: listing.user_id).includes(:levels, :session, :user)
    users = candidates.select { |candidate| matcher.match_between?(listing, candidate) }.map(&:user).uniq

    users.each do |user|
      PlayerSuggestionPushService.notify_user(
        user: user,
        event_type: "listing_created",
        fingerprint: "listing-created-#{listing.id}-#{user.id}",
        title: "Nouveau joueur compatible",
        body: "#{listing.user.full_name} vient de se rendre disponible.",
        url: Rails.application.routes.url_helpers.player_listings_path
      )
    end
  end

  def notify_session_event(event_type, session_id)
    session = Session.includes(:levels, :participants).find_by(id: session_id)
    return if session.blank? || !session.open_for_matching?

    User.activated.find_each do |user|
      next if user.id == session.user_id
      next unless PlayerSuggestionsService.new(user).session_relevant?(session)

      PlayerSuggestionPushService.notify_user(
        user: user,
        event_type: event_type,
        fingerprint: "#{event_type}-#{session.id}-#{user.id}",
        title: session_notification_title(event_type),
        body: "Session ouverte: #{session.title} le #{I18n.l(session.start_at, format: :short)}.",
        url: Rails.application.routes.url_helpers.player_listings_path
      )
    end
  end

  def session_notification_title(event_type)
    case event_type
    when "session_spot_released"
      "Une place s'est liberee"
    else
      "Nouvelle session ouverte"
    end
  end
end
