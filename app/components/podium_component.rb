# frozen_string_literal: true

# Podium des trois premiers d'un classement. Les marches sont rendues dans
# l'ordre visuel 2-1-3, mais la liste reste dans l'ordre du classement pour les
# lecteurs d'écran (réordonnée en CSS).
class PodiumComponent < ApplicationComponent
  MEDALS = { 1 => "🥇", 2 => "🥈", 3 => "🥉" }.freeze
  STEPS = {
    1 => { order: "order-2", height: "h-24", tone: "bg-gradient-to-b from-amber-300 to-asmbv-gold text-white", delay: "[animation-delay:150ms]" },
    2 => { order: "order-1", height: "h-16", tone: "bg-gradient-to-b from-gray-200 to-gray-300 text-gray-600", delay: "[animation-delay:0ms]" },
    3 => { order: "order-3", height: "h-11", tone: "bg-gradient-to-b from-orange-200 to-orange-300 text-orange-800", delay: "[animation-delay:300ms]" }
  }.freeze

  def initialize(players:, title:, empty_message: "Aucune donnée", current_user_id: nil)
    @players = players || []
    @title = title
    @empty_message = empty_message
    @current_user_id = current_user_id
  end

  private

  attr_reader :players, :title, :empty_message, :current_user_id

  def has_players?
    players.any?
  end

  # Toujours trois marches : une place vide garde la silhouette du podium.
  def places
    (1..3).map { |position| [ position, players[position - 1] ] }
  end

  def step(position)
    STEPS.fetch(position)
  end

  def medal_emoji(position)
    MEDALS.fetch(position, "")
  end

  def me?(player)
    current_user_id.present? && player[:user]&.id == current_user_id
  end

  def score(player)
    PlayerScore.new(player)
  end

  def avatar_size(position)
    position == 1 ? :lg : :md
  end
end
