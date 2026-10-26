module Admin
  class StagesController < BaseController
    load_and_authorize_resource
    before_action :set_stage, only: [ :show, :edit, :update ]

    def index
      @table = Admin::Tables::Stages.new
      @state = DataTable::State.new(params)
      @page = Pagination.new(scope: DataTable::Query.call(relation: @stages.includes(:main_coach, :assistant_coach), definition: @table, state: @state),
                             page: @state.page, per_page: 25)
    end

    def show
    end

    def new
      @stage = Stage.new
    end

    def create
      @stage = Stage.new(stage_params)
      redirect_or_render(@stage.save, :new, to: [ :admin, @stage ], notice: "Stage créé avec succès.")
    end

    def edit
    end

    def update
      redirect_or_render(@stage.update(stage_params), :edit, to: [ :admin, @stage ], notice: "Stage mis à jour avec succès.")
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
