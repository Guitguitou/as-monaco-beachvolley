# frozen_string_literal: true

module Admin
  class TerrainClosuresController < BaseController
    before_action :require_admin!
    before_action :set_terrain_closure, only: [ :edit, :update, :destroy ]

    def index
      @table = Admin::Tables::TerrainClosures.new
      @state = DataTable::State.new(params)
      @page = Pagination.new(scope: DataTable::Query.call(relation: TerrainClosure.includes(:terrain), definition: @table, state: @state),
                             page: @state.page, per_page: 25)
    end

    def new
      @terrain_closure = TerrainClosure.new
    end

    def create
      @terrain_closure = TerrainClosure.new(terrain_closure_params)
      redirect_or_render(@terrain_closure.save, :new, to: admin_terrain_closures_path, notice: "Indisponibilité enregistrée.")
    end

    def edit; end

    def update
      redirect_or_render(@terrain_closure.update(terrain_closure_params), :edit, to: admin_terrain_closures_path, notice: "Indisponibilité mise à jour.")
    end

    def destroy
      @terrain_closure.destroy
      redirect_to admin_terrain_closures_path, notice: "Indisponibilité supprimée."
    end

    private

    def set_terrain_closure
      @terrain_closure = TerrainClosure.find(params[:id])
    end

    def terrain_closure_params
      params.require(:terrain_closure).permit(:terrain_id, :starts_on, :ends_on, :reason)
    end
  end
end
