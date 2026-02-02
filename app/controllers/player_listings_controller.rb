# frozen_string_literal: true

class PlayerListingsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  def index
    build_index_context
  end

  def create
    @player_listing = current_user.player_listings.new(player_listing_params)
    authorize! :create, @player_listing

    if @player_listing.save
      redirect_to player_listings_path, notice: "Annonce créée avec succès."
    else
      build_index_context
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @player_listing = current_user.player_listings.find(params[:id])
    authorize! :update, @player_listing

    if @player_listing.update(player_listing_params)
      redirect_to player_listings_path, notice: "Annonce mise à jour."
    else
      build_index_context
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @player_listing = current_user.player_listings.find(params[:id])
    authorize! :destroy, @player_listing

    @player_listing.destroy
    redirect_to player_listings_path, notice: "Annonce supprimée."
  end

  private

  def player_listing_params
    params.require(:player_listing).permit(
      :listing_type, :session_id, :gender, :date, :starts_at, :ends_at, :status, :notes,
      level_ids: []
    )
  end

  def build_index_context
    @player_listing ||= current_user.player_listings.new
    @my_listings = current_user.player_listings.includes(:levels, :session).order(created_at: :desc)
    @matches = PlayerMatchingService.new(current_user).matches
    @incoming_requests = PlayerRequest.pending.where(to_user: current_user).includes(:player_listing, :from_user)
    @outgoing_requests = PlayerRequest.pending.where(from_user: current_user).includes(:player_listing, :to_user)
    @levels = Level.all
    @sessions = Session.upcoming.ordered_by_start
  end
end
