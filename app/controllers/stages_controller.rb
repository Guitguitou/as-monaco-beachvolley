class StagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stage, only: [:show]

  def index
    ordered = Stage.ordered_for_players
    @current_or_next = ordered.find { |s| s.current_or_upcoming? }
    @others = ordered.reject { |s| s == @current_or_next }
  end

  def show
  end

  private

  def set_stage
    @stage = Stage.find(params[:id])
  end
end
