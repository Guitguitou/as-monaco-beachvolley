# frozen_string_literal: true

class RankingComponent < ApplicationComponent
  def initialize(players:, title: nil)
    @players = players || []
    @title = title
  end

  private

  attr_reader :players, :title

  def has_players?
    players.any?
  end
end
