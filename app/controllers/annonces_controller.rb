# frozen_string_literal: true

class AnnoncesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_annonce, only: [ :show, :edit, :update, :destroy, :confirm, :cancel, :toggle_availability ]

  def index
    authorize! :read, Annonce
    @eligible_annonces = Annonces::EligibleAnnoncesQuery.call(user: current_user)
    @my_annonces = Annonce.where(user_id: current_user.id).ordered_by_recent.includes(:levels, slots: :availabilities)
  end

  def show
    authorize! :read, @annonce
    @available_slot_ids = current_slot_ids_for(current_user)
  end

  def new
    authorize! :create, Annonce
    @annonce = Annonce.new
    2.times { @annonce.slots.build }
  end

  def create
    @annonce = Annonce.new(annonce_params)
    @annonce.user = current_user
    authorize! :create, @annonce

    if @annonce.save
      Annonces::CreationNotifier.new(annonce: @annonce).notify_eligible_players
      redirect_to @annonce, notice: "Annonce publiée ✅ Les joueurs éligibles ont été prévenus."
    else
      @annonce.slots.build if @annonce.slots.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @annonce
  end

  def update
    authorize! :update, @annonce
    if @annonce.update(annonce_params)
      redirect_to @annonce, notice: "Annonce mise à jour ✅"
    else
      @annonce.slots.build if @annonce.slots.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @annonce
    @annonce.destroy
    redirect_to annonces_path, notice: "Annonce supprimée."
  end

  # Un joueur (dé)clare sa disponibilité sur un créneau de l'annonce.
  def toggle_availability
    authorize! :toggle_availability, @annonce
    slot = @annonce.slots.find(params[:slot_id])
    availability = AnnonceAvailability.find_by(annonce_slot: slot, user: current_user)

    if availability
      availability.destroy
    else
      AnnonceAvailability.create(annonce_slot: slot, user: current_user)
      Annonces::CreationNotifier.new(annonce: @annonce).notify_creator_of_response(from: current_user)
    end

    redirect_to @annonce
  end

  # GET : formulaire de choix du créneau + terrain. PATCH : confirmation effective.
  def confirm
    authorize! :confirm, @annonce

    if request.get?
      @confirmable_slots = @annonce.confirmable_slots
      @terrains_by_slot_id = @confirmable_slots.index_with do |slot|
        Annonces::AvailableTerrainsForSlotQuery.call(slot: slot)
      end
      return
    end

    slot = @annonce.slots.find(params[:slot_id])
    terrain = params[:terrain]
    result = Annonces::ConfirmationService.new(annonce: @annonce, slot: slot, terrain: terrain).call
    Annonces::CreationNotifier.new(annonce: @annonce).notify_confirmed(session: result.session, users: result.registered)

    notice = "Session de jeu libre créée 🎉 #{result.registered.size} joueur(s) inscrit(s)."
    notice += " #{result.skipped.size} ignoré(s) (crédits/conflit)." if result.skipped.any?
    redirect_to result.session, notice: notice
  rescue ActiveRecord::RecordInvalid => e
    redirect_to confirm_annonce_path(@annonce), alert: "Confirmation impossible : #{e.record.errors.full_messages.to_sentence.presence || e.message}"
  end

  def cancel
    authorize! :cancel, @annonce
    @annonce.cancelled!
    redirect_to annonces_path, notice: "Annonce annulée."
  end

  private

  def set_annonce
    @annonce = Annonce.includes(:levels, slots: { availabilities: :user }).find(params[:id])
  end

  def current_slot_ids_for(user)
    AnnonceAvailability
      .where(annonce_slot_id: @annonce.slots.select(:id), user_id: user.id)
      .pluck(:annonce_slot_id)
      .to_set
  end

  def annonce_params
    params.require(:annonce).permit(
      :title, :description, :min_players,
      level_ids: [],
      slots_attributes: [ :id, :start_at, :end_at, :_destroy ]
    )
  end
end
