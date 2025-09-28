class StagesController < ApplicationController
  before_action :authenticate_user!

  def index
    ordered = Stage.ordered_for_players
    @current_or_next = ordered.find { |s| s.current_or_upcoming? }
    @others = ordered.reject { |s| s == @current_or_next }
  end
end
