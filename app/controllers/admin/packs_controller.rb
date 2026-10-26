module Admin
  class PacksController < BaseController
    before_action :require_admin!
    before_action :set_pack, only: [ :edit, :update, :destroy ]

    def index
      @packs = Pack.ordered.includes(:stage)
    end

    def new
      @pack = Pack.new(active: true, pack_type: "credits")
      @stages = Stage.ordered_for_players
    end

    def create
      @pack = Pack.new(pack_params)
      @stages = Stage.ordered_for_players

      redirect_or_render(@pack.save, :new, to: admin_packs_path, notice: "Pack créé avec succès")
    end

    def edit
      @stages = Stage.ordered_for_players
    end

    def update
      @stages = Stage.ordered_for_players

      redirect_or_render(@pack.update(pack_params), :edit, to: admin_packs_path, notice: "Pack mis à jour avec succès")
    end

    def destroy
      @pack.destroy
      redirect_to admin_packs_path, notice: "Pack supprimé"
    end

    private

    def set_pack
      @pack = Pack.find(params[:id])
    end

    def pack_params
      params.require(:pack).permit(:name, :description, :pack_type, :amount_cents, :credits, :stage_id, :active, :position, :public)
    end
  end
end
