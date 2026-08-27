# frozen_string_literal: true

# Carte de session « façon affiche de match ».
#
# L'ancienne carte de grille n'avait aucun bouton d'inscription : elle affichait
# « DÉTAILS → », un faux bouton, et il fallait ouvrir la fiche puis scroller
# pour trouver l'action. Son élément le plus gros était le prix — y compris
# quand il valait zéro.
#
# Ici : le type et le terrain colorent l'en-tête, la date passe en display, les
# inscrits ont un visage, les places sont formulées, et l'action est un bouton
# pleine largeur qui agit sans quitter la page.
class SessionCardComponent < ApplicationComponent
  MAX_AVATARS = 4

  def initialize(state:, return_params: {})
    @state = state
    @return_params = return_params
  end

  def dom_id
    "session_card_#{session.id}"
  end

  private

  attr_reader :state, :return_params

  delegate :session, :accent, :registered?, :waitlisted?, :full?, :conflict?,
           :off_level?, :confirmed_count, :action, :action_label,
           :destructive_action?, :actionable?, :confirmed_participants,
           to: :state

  def card_classes
    "flex flex-col bg-white border border-gray-200 rounded-xl shadow-sm " \
      "transition-shadow duration-150 hover:shadow-md"
  end

  # Une seule barre de couleur, celle du terrain : le type de session est déjà
  # nommé et coloré par sa pastille juste en dessous. Reprend les couleurs du
  # calendrier pour que le joueur reconnaisse son terrain avant de lire.
  def terrain_bar_classes
    case session.terrain
    when "Terrain 1" then "bg-[#0052a3]"
    when "Terrain 2" then "bg-[#1a1a1a]"
    when "Terrain 3" then "bg-[#d4af37]"
    else "bg-gray-300"
    end
  end

  def terrain_label
    session.terrain.to_s.split("_").last
  end

  def title
    session.title.presence || session.display_name
  end

  def day_label
    l(session.start_at.to_date, format: :day_and_month)
  end

  def time_range
    "#{l(session.start_at, format: :time)} – #{l(session.end_at, format: :time)}"
  end

  def duration
    session_duration(session.start_at, session.end_at)
  end

  def spots_label
    spots_left_label(confirmed_count, session.max_players)
  end

  def price_label
    credits_label(session.price)
  end

  def extra_participants
    [ confirmed_participants.size - MAX_AVATARS, 0 ].max
  end

  def action_button_classes
    base = "w-full inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2.5 " \
           "text-sm font-semibold focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2"

    if !actionable?
      "#{base} bg-gray-100 text-gray-500 border border-gray-200 cursor-not-allowed"
    elsif destructive_action?
      "#{base} bg-white text-asmbv-red border border-asmbv-red hover:bg-asmbv-red/5 focus-visible:ring-asmbv-red"
    elsif action == :waitlist
      "#{base} bg-gray-900 text-white hover:bg-gray-800 focus-visible:ring-gray-900"
    else
      "#{base} bg-asmbv-red text-white hover:bg-asmbv-red-dark focus-visible:ring-asmbv-red"
    end
  end

  def action_icon
    case action
    when :unregister, :leave_waitlist then "x-circle"
    when :waitlist then "clock"
    when :register then "check-circle"
    else "lock"
    end
  end

  # L'inscription et la désinscription passent par la même route REST.
  # `from: "card"` indique au contrôleur de répondre en Turbo Stream, pour
  # remplacer cette carte au lieu de rediriger vers la fiche session.
  def action_path
    if destructive_action?
      helpers.session_registration_path(session, return_params.merge(id: "current", from: "card"))
    else
      helpers.session_registrations_path(session, return_params.merge(from: "card"))
    end
  end

  def action_method
    destructive_action? ? :delete : :post
  end

  def action_params
    action == :waitlist ? { waitlist: true } : {}
  end

  def confirm_message
    return nil unless destructive_action?
    return nil unless session.entrainement? && session.cancellation_deadline_at.present?
    return nil if Time.current <= session.cancellation_deadline_at

    "Le délai est dépassé : tu ne seras pas remboursé. Confirmer la désinscription ?"
  end
end
