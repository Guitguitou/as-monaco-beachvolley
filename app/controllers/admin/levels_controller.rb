# frozen_string_literal: true

module Admin
  class LevelsController < ApplicationController
    layout "dashboard"
    before_action :set_level, only: [ :show, :edit, :update, :destroy ]

    def index
      @levels = Level.all.order(:name)
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
