# frozen_string_literal: true

class PodiumComponent < ViewComponent::Base
  def initialize(players:, title:, icon: "trophy", empty_message: "Aucune donnée")
    @players = players || []
    @title = title
    @icon = icon
    @empty_message = empty_message
  end

  private

  attr_reader :players, :title, :icon, :empty_message

  def has_players?
    players.any?
  end

  def first_place
    players[0]
  end

  def second_place
    players[1]
  end

  def third_place
    players[2]
  end

  def medal_emoji(position)
    case position
    when 1 then "🥇"
    when 2 then "🥈"
    when 3 then "🥉"
    else ""
    end
  end
end

