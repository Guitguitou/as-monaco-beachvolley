class StagesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_stage, only: [:show]

  def index
    ordered = Stage.ordered_for_players
    @upcoming_stages = ordered.select { |s| s.current_or_upcoming? }
    @past_stages = ordered.select { |s| !s.current_or_upcoming? }
    
    # Le prochain stage (le premier à venir)
    @next_stage = @upcoming_stages.first
    # Les autres stages à venir (sans le prochain)
    @other_upcoming_stages = @upcoming_stages[1..-1] || []
  end

  def show
    @stage_packs = @stage.packs.active.ordered
  end

  private

  def set_stage
    @stage = Stage.find(params[:id])
  end
end
