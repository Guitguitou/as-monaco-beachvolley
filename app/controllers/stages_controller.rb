class StagesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_stage, only: [:show]

  def index
    ordered = Stage.ordered_for_players
    @current_or_next = ordered.find { |s| s.current_or_upcoming? }
    @others = ordered.reject { |s| s == @current_or_next }
  end

  def show
    @stage_packs = @stage.packs.active.ordered
  end

  private

  def set_stage
    @stage = Stage.find(params[:id])
  end
end
