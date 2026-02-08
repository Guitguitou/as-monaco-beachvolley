module Admin
  class StagesController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    load_and_authorize_resource
    before_action :set_stage, only: [:show, :edit, :update]

    PER_PAGE = 25

    def index
      @stages = @stages.order(starts_on: :desc)
      @total_stages_count = @stages.count
      @total_pages = (@total_stages_count.to_f / PER_PAGE).ceil
      requested_page = params.fetch(:page, 1).to_i
      @current_page = [requested_page, 1].max
      upper_bound = [@total_pages, 1].max
      @current_page = [@current_page, upper_bound].min
      offset = (@current_page - 1) * PER_PAGE
      @stages = @stages.limit(PER_PAGE).offset(offset)
    end

    def show
    end

    def new
      @stage = Stage.new
    end

    def create
      @stage = Stage.new(stage_params)
      if @stage.save
        redirect_to admin_stage_path(@stage), notice: "Stage créé avec succès."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @stage.update(stage_params)
        redirect_to admin_stage_path(@stage), notice: "Stage mis à jour avec succès."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_stage
      @stage = Stage.find(params[:id])
    end

    def stage_params
      params.require(:stage).permit(:title, :description, :starts_on, :ends_on, :image, :main_coach_id, :assistant_coach_id, :price, :registration_link)
    end
  end
end
