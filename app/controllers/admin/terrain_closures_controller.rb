# frozen_string_literal: true

module Admin
  class TerrainClosuresController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_terrain_closure, only: [:edit, :update, :destroy]

    def index
      @terrain_closures = TerrainClosure.order(starts_on: :desc, terrain: :asc)
    end

    def new
      @terrain_closure = TerrainClosure.new
    end

    def create
      @terrain_closure = TerrainClosure.new(terrain_closure_params)
      if @terrain_closure.save
        redirect_to admin_terrain_closures_path, notice: "Indisponibilité enregistrée."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @terrain_closure.update(terrain_closure_params)
        redirect_to admin_terrain_closures_path, notice: "Indisponibilité mise à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @terrain_closure.destroy
      redirect_to admin_terrain_closures_path, notice: "Indisponibilité supprimée."
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès non autorisé" unless current_user&.admin?
    end

    def set_terrain_closure
      @terrain_closure = TerrainClosure.find(params[:id])
    end

    def terrain_closure_params
      params.require(:terrain_closure).permit(:terrain, :starts_on, :ends_on, :reason)
    end
  end
end
