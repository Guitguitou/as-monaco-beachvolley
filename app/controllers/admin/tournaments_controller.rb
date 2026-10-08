module Admin
  class TournamentsController < BaseController
    load_and_authorize_resource

    def index
      @tournaments = @tournaments.order(starts_on: :desc)
    end

    def show
      @pack = @tournament.pack
    end

    def new
      @tournament.assign_attributes(start_time: "10:00", end_time: "16:00", level: "S3", terrains: Session.terrains.values)
    end

    def create
      @tournament = Tournament.new(tournament_params)
      if save_tournament
        redirect_to admin_tournament_path(@tournament), notice: "Tournoi créé. Le paiement est fermé : ouvre-le quand les inscriptions BVS sont validées."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @tournament.assign_attributes(tournament_params)
      if save_tournament
        redirect_to admin_tournament_path(@tournament), notice: "Tournoi mis à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      Tournaments::Destroy.new(tournament: @tournament).call
      redirect_to admin_tournaments_path, notice: "Tournoi supprimé."
    end

    def toggle_payment
      pack = @tournament.pack
      pack.update!(active: !pack.active?)
      redirect_to admin_tournament_path(@tournament), notice: pack.active? ? "Paiement ouvert." : "Paiement fermé."
    end

    def reorder_images
      @tournament.reorder_images(Array(params[:ids]))
      head :no_content
    end

    def remove_image
      @tournament.images.attachments.find(params[:attachment_id]).purge
      redirect_to admin_tournament_path(@tournament), notice: "Image supprimée."
    end

    private

    # Les nouvelles images s'ajoutent aux existantes au lieu de les remplacer.
    def save_tournament
      new_images = Array(params.dig(:tournament, :images)).compact_blank
      @tournament.images.attach(new_images) if new_images.any?
      Tournaments::Save.new(tournament: @tournament, owner: current_user).call
    end

    def tournament_params
      params.require(:tournament).permit(
        :title, :description, :starts_on, :ends_on, :start_time, :end_time, :level, :points,
        :teams_count, :location, :registration_link, :price, terrain_names: []
      )
    end
  end
end
