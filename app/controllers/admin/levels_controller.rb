# frozen_string_literal: true

module Admin
  class LevelsController < ApplicationController
    layout "dashboard"
    before_action :set_level, only: [:show, :edit, :update, :destroy]

    PER_PAGE = 25

    def index
      @levels = Level.all.order(:name)
      @total_levels_count = @levels.count
      @total_pages = (@total_levels_count.to_f / PER_PAGE).ceil
      requested_page = params.fetch(:page, 1).to_i
      @current_page = [requested_page, 1].max
      upper_bound = [@total_pages, 1].max
      @current_page = [@current_page, upper_bound].min
      offset = (@current_page - 1) * PER_PAGE
      @levels = @levels.limit(PER_PAGE).offset(offset)
    end

    def show; end

    def new
      @level = Level.new
    end

    def create
      @level = Level.new(level_params)
      if @level.save
        redirect_to admin_levels_path, notice: "Groupe de niveau créé avec succès"
      else
        render :new
      end
    end

    def edit; end

    def update
      if @level.update(level_params)
        redirect_to admin_levels_path, notice: "Groupe de niveau mis à jour"
      else
        render :edit
      end
    end

    def destroy
      @level.destroy
      redirect_to admin_levels_path, notice: "Groupe supprimé"
    end

    private

    def set_level
      @level = Level.find(params[:id])
    end

    def level_params
      params.require(:level).permit(:name, :gender, :color)
    end
  end
end
