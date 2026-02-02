# frozen_string_literal: true

class PlayerRequestsController < ApplicationController
  before_action :authenticate_user!

  def create
    listing = PlayerListing.find(params[:player_listing_id])
    @player_request = PlayerRequest.new(
      player_listing: listing,
      from_user: current_user,
      to_user: listing.user,
      message: params[:message]
    )
    authorize! :create, @player_request

    if @player_request.save
      redirect_to player_listings_path, notice: "Demande envoyée."
    else
      redirect_to player_listings_path, alert: @player_request.errors.full_messages.to_sentence
    end
  end

  def accept
    @player_request = PlayerRequest.find(params[:id])
    authorize! :update, @player_request

    @player_request.update!(status: :accepted)
    redirect_to player_listings_path, notice: "Demande acceptée."
  end

  def decline
    @player_request = PlayerRequest.find(params[:id])
    authorize! :update, @player_request

    @player_request.update!(status: :declined)
    redirect_to player_listings_path, notice: "Demande refusée."
  end
end
