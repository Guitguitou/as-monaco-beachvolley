# frozen_string_literal: true

module Admin
  # Terrains du club : création, renommage, couleur (palette fermée), ordre,
  # archivage. Un terrain avec historique ne se supprime pas, il s'archive.
  class TerrainsController < BaseController
    before_action :require_admin!
    before_action :set_terrain, except: [ :index, :new, :create ]

    def index
      terrains = Terrain.ordered.to_a
      @active_terrains = terrains.reject(&:archived?)
      @archived_terrains = terrains.select(&:archived?)
    end

    def new
      @terrain = Terrain.new
    end

    def create
      @terrain = Terrain.new(terrain_params)
      redirect_or_render(@terrain.save, :new, to: admin_terrains_path, notice: "Terrain créé.")
    end

    def edit; end

    def update
      redirect_or_render(@terrain.update(terrain_params), :edit, to: admin_terrains_path, notice: "Terrain mis à jour.")
    end

    def move
      Terrains::Reorder.new(@terrain).move(params[:direction].to_s)
      redirect_to admin_terrains_path
    end

    def archive
      @terrain.archive!
      redirect_to admin_terrains_path, notice: "Terrain archivé."
    end

    def unarchive
      @terrain.update!(archived_at: nil)
      redirect_to admin_terrains_path, notice: "Terrain réactivé."
    end

    def destroy
      if @terrain.destroy
        redirect_to admin_terrains_path, notice: "Terrain supprimé."
      else
        redirect_to admin_terrains_path, alert: @terrain.errors.full_messages.to_sentence
      end
    end

    private

    def set_terrain
      @terrain = Terrain.find(params[:id])
    end

    def terrain_params
      params.require(:terrain).permit(:name, :color)
    end
  end
end
