# frozen_string_literal: true

# Classement complet, avec une barre proportionnelle au meilleur score. Le
# contrôleur Stimulus `ranking` gère la recherche, le dépliage au-delà des
# `visible` premiers et le bouton « Me trouver ».
class RankingComponent < ApplicationComponent
  RANK_TONES = {
    1 => "bg-asmbv-gold text-white",
    2 => "bg-gray-300 text-gray-700",
    3 => "bg-orange-300 text-orange-900"
  }.freeze

  def initialize(players:, current_user_id: nil, visible: 10)
    @players = players || []
    @current_user_id = current_user_id
    @visible = visible
  end

  private

  attr_reader :players, :current_user_id, :visible

  def has_players?
    players.any?
  end

  def hidden_count
    [ players.size - visible, 0 ].max
  end

  def me?(player)
    current_user_id.present? && player[:user]&.id == current_user_id
  end

  def includes_me?
    players.any? { |player| me?(player) }
  end

  def bar_width(player)
    max = players.first[:count].to_f
    return 0 if max.zero?

    (player[:count] / max * 100).round
  end

  def rank_classes(rank)
    "grid h-7 w-7 shrink-0 place-items-center rounded-full text-xs font-bold tabular-nums " \
      "#{RANK_TONES.fetch(rank, 'bg-gray-100 text-gray-500')}"
  end

  def row_classes(player)
    "flex items-center gap-3 px-2 py-2 rounded-lg transition-colors " \
      "#{me?(player) ? 'bg-asmbv-red/5 ring-1 ring-asmbv-red/30' : 'hover:bg-gray-50'}"
  end

  def score(player)
    PlayerScore.new(player)
  end

  def search_key(player)
    I18n.transliterate(player[:name].to_s).downcase
  end
end
