class StagesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_stage, only: [:show]

  def index
    ordered = Stage.ordered_for_players
    @upcoming_stages = ordered.select { |s| s.current_or_upcoming? }
    @past_stages = ordered.select { |s| !s.current_or_upcoming? }
  end

  def show
    @stage_packs = @stage.packs.active.ordered
  end

  private

  def set_stage
    @stage = Stage.find(params[:id])
  end
end
