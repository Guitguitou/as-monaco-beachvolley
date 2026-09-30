# frozen_string_literal: true

# Un créneau de jeu libre à rejoindre, en une carte : quand, combien il en
# manque, qui en est déjà, et « J'en suis » en un tap.
#
# Pensée pour le joueur qui ne connaît pas grand monde : voir les prénoms de
# ceux qui y vont et « il manque 1 joueur » rassure plus qu'un titre d'annonce.
class PlaySlotCardComponent < ApplicationComponent
  MAX_NAMES = 4

  def initialize(slot:, user:)
    @slot = slot
    @user = user
  end

  private

  attr_reader :slot, :user

  delegate :annonce, :missing_players, to: :slot

  def own?
    annonce.user_id == user.id
  end

  def joined?
    slot.availabilities.any? { |availability| availability.user_id == user.id }
  end

  def players
    slot.availabilities.map(&:user)
  end

  # Le titre par défaut répète la date déjà affichée : on nomme plutôt l'organisateur.
  def subtitle
    return annonce.title unless annonce.title == Annonces::DefaultTitle.for(annonce)

    "Partie de #{annonce.user.first_name.presence || annonce.user.full_name}"
  end

  def player_names
    names = players.first(MAX_NAMES).map { |player| player.first_name.presence || player.full_name }
    extra = players.size - MAX_NAMES
    extra.positive? ? "#{names.join(', ')} +#{extra}" : names.join(", ")
  end

  # Une pastille par joueur attendu, pleine pour chaque joueur qui en est.
  def dots
    Array.new([ annonce.min_players, players.size ].max) { |index| index < players.size }
  end

  def status_label
    return "Ça joue ! Confirmation en cours" if missing_players.zero?

    "Il manque #{missing_players} #{missing_players == 1 ? 'joueur' : 'joueurs'}"
  end

  def status_classes
    missing_players.zero? ? "text-green-700" : "text-asmbv-red"
  end

  def day_label
    l(slot.start_at.to_date, format: :short_day)
  end

  def time_label
    "#{l(slot.start_at, format: :time)}–#{l(slot.end_at, format: :time)}"
  end

  def price_hint
    "#{credits_label(Session::FREE_PLAY_PRICE)} si la partie est confirmée"
  end

  def toggle_path
    helpers.toggle_availability_annonce_path(annonce, slot_id: slot.id)
  end

  def toggle_classes
    base = "inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-semibold w-full sm:w-auto"
    return "#{base} border border-gray-300 text-gray-700 hover:bg-gray-100" if joined?

    "#{base} text-white bg-asmbv-red hover:bg-asmbv-red-dark"
  end
end
