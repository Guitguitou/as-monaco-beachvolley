# frozen_string_literal: true

# Score affiché pour une ligne de classement : nombre de sessions, ou durée
# d'inactivité pour « Le frigo ». Partagé par le podium et le classement.
class PlayerScore
  def initialize(player)
    @player = player
  end

  def value
    return player[:count] if player[:count]
    return player[:days_since] if player[:days_since]

    "—"
  end

  def unit
    return (player[:count] > 1 ? "sessions" : "session") if player[:count]
    return (player[:days_since] > 1 ? "jours" : "jour") if player[:days_since]

    "jamais joué"
  end

  def detail
    return unless player[:last_session_at]

    "depuis le #{player[:last_session_at].in_time_zone('Europe/Paris').strftime('%d/%m/%Y')}"
  end

  private

  attr_reader :player
end
