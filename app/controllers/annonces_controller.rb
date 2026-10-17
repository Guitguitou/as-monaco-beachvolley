# frozen_string_literal: true

# Jeu libre : parties lancées par les joueurs (modèle Annonce), où chacun
# indique sur quels créneaux il en est, jusqu'à la confirmation en session.
class AnnoncesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_annonce, only: [ :show, :edit, :update, :destroy, :confirm, :cancel, :toggle_availability ]

  def index
    authorize! :read, Annonce
    @board = Annonces::Board.new(user: current_user)
  end

  def show
    authorize! :read, @annonce
    @available_slot_ids = current_slot_ids_for(current_user)
    @terrain_free_by_slot = @annonce.upcoming_slots.index_with { |slot| Annonces::AvailableTerrainsForSlotQuery.call(slot: slot).any? }
  end

  def new
    authorize! :create, Annonce
    @annonce = Annonce.new(levels: current_user.levels)
    2.times { @annonce.slots.build }
  end

  def create
    @annonce = Annonce.new(annonce_params)
    @annonce.user = current_user
    authorize! :create, @annonce

    if @annonce.save
      Annonces::Notifier.new(annonce: @annonce).notify_eligible_players
      redirect_to @annonce, notice: "Partie lancée ✅ Les joueurs éligibles ont été prévenus."
    else
      @annonce.slots.build if @annonce.slots.empty?
      render :new, status: :unprocessable_entity
    end
  end

  # « Tu es libre quand ? » : rejoint une partie existante sur ce moment, ou en lance une.
  def quick
    authorize! :create, Annonce
    quick_slot = Annonces::QuickSlot.find(params[:slot])
    return redirect_back(fallback_location: annonces_path, alert: "Ce créneau n'est plus disponible.") unless quick_slot

    result = Annonces::QuickPlay.new(user: current_user, quick_slot: quick_slot).call
    notice = result.joined ? "Une partie existait déjà sur ce créneau : tu en es ✅" : "Partie lancée ✅ Les joueurs éligibles ont été prévenus."
    redirect_to result.annonce, notice: notice
  end

  def edit
    authorize! :update, @annonce
  end

  def update
    authorize! :update, @annonce
    if @annonce.update(annonce_params)
      redirect_to @annonce, notice: "Partie mise à jour ✅"
    else
      @annonce.slots.build if @annonce.slots.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @annonce
    @annonce.destroy
    redirect_to annonces_path, notice: "Partie supprimée."
  end

  # Un joueur (dé)clare sa disponibilité sur un créneau à venir, depuis la
  # partie ou depuis l'accueil : il reste sur la page d'où il vient.
  def toggle_availability
    authorize! :toggle_availability, @annonce
    Annonces::AvailabilityToggle.new(annonce: @annonce, slot: @annonce.slots.upcoming.find(params[:slot_id]), user: current_user).call
    redirect_back fallback_location: annonce_path(@annonce)
  end

  # GET : formulaire de choix du créneau + terrain. PATCH : confirmation effective.
  def confirm
    authorize! :confirm, @annonce

    return prepare_confirmation if request.get?

    slot = @annonce.slots.upcoming.find(params[:slot_id])
    result = Annonces::ConfirmationService.new(annonce: @annonce, slot: slot, terrain: params[:terrain]).call
    Annonces::Notifier.new(annonce: @annonce).notify_confirmed(session: result.session, users: result.registered)
    redirect_to result.session, notice: result.summary
  rescue ActiveRecord::RecordInvalid => e
    redirect_to confirm_annonce_path(@annonce), alert: "Confirmation impossible : #{e.record.errors.full_messages.to_sentence.presence || e.message}"
  end

  def cancel
    authorize! :cancel, @annonce
    @annonce.cancelled!
    redirect_to annonces_path, notice: "Partie annulée."
  end

  private

  def prepare_confirmation
    @confirmable_slots = @annonce.confirmable_slots
    @terrains_by_slot_id = @confirmable_slots.index_with { |slot| Annonces::AvailableTerrainsForSlotQuery.call(slot: slot) }
  end

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
