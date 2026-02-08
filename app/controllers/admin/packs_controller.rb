module Admin
  class PacksController < ApplicationController
    layout 'dashboard'
    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :set_pack, only: [:edit, :update, :destroy]

    PER_PAGE = 25

    def index
      @packs = Pack.ordered.includes(:stage)
      @total_packs_count = @packs.count
      @total_pages = (@total_packs_count.to_f / PER_PAGE).ceil
      requested_page = params.fetch(:page, 1).to_i
      @current_page = [requested_page, 1].max
      upper_bound = [@total_pages, 1].max
      @current_page = [@current_page, upper_bound].min
      offset = (@current_page - 1) * PER_PAGE
      @packs = @packs.limit(PER_PAGE).offset(offset)
    end

    def new
      @pack = Pack.new(active: true, pack_type: 'credits')
      @stages = Stage.ordered_for_players
    end

    def create
      @pack = Pack.new(pack_params)
      @stages = Stage.ordered_for_players
      
      if @pack.save
        redirect_to admin_packs_path, notice: "Pack créé avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @stages = Stage.ordered_for_players
    end

    def update
      @stages = Stage.ordered_for_players
      
      if @pack.update(pack_params)
        redirect_to admin_packs_path, notice: "Pack mis à jour avec succès"
      else
        render :edit, status: :unprocessable_entity
      end
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
      params.require(:pack).permit(:name, :description, :pack_type, :amount_cents, :credits, :stage_id, :active, :position)
    end

    def ensure_admin!
      redirect_to root_path, alert: "Accès interdit" unless current_user.admin?
    end
  end
end
