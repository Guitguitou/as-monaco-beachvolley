# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Player listings", type: :request do
  let(:user) { create(:user, activated_at: Time.current) }

  before do
    sign_in user
  end

  describe "POST /player_listings" do
    context "with valid params" do
      it "creates a listing so players can announce availability" do
        post player_listings_path, params: {
          player_listing: {
            listing_type: "disponible",
            date: "2026-01-20",
            starts_at: "10:00",
            ends_at: "12:00"
          }
        }

        expect(response).to redirect_to(player_listings_path)
        expect(PlayerListing.count).to eq(1)
      end
    end
  end

  describe "PATCH /player_requests/:id/accept" do
    context "when the recipient accepts" do
      it "updates the request to accepted to confirm the match" do
        recipient = create(:user, activated_at: Time.current)
        listing = create(:player_listing, user: recipient)
        request = create(:player_request, player_listing: listing, to_user: recipient)

        sign_in recipient
        patch accept_player_request_path(request)

        expect(response).to redirect_to(player_listings_path)
        expect(request.reload.status).to eq("accepted")
      end
    end
  end

  describe "PATCH /player_requests/:id/decline" do
    context "when the recipient declines" do
      it "updates the request to declined to close the discussion" do
        recipient = create(:user, activated_at: Time.current)
        listing = create(:player_listing, user: recipient)
        request = create(:player_request, player_listing: listing, to_user: recipient)

        sign_in recipient
        patch decline_player_request_path(request)

        expect(response).to redirect_to(player_listings_path)
        expect(request.reload.status).to eq("declined")
      end
    end
  end
end
