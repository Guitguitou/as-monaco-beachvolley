# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayerListingsController, type: :controller do
  include ActiveJob::TestHelper

  describe "POST #create" do
    context "when an active availability is created" do
      let(:user) { create(:user, :admin, activated_at: Time.current) }

      before do
        ActiveJob::Base.queue_adapter = :test
        clear_enqueued_jobs
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:authenticate_user!).and_return(true)
      end

      it "enqueues suggestion notifications so compatible players are informed" do
        post :create, params: {
          player_listing: {
            listing_type: "disponible",
            date: "2026-03-01",
            starts_at: "10:00",
            ends_at: "12:00"
          }
        }

        expect(response).to redirect_to(player_listings_path)
        expect(NotifyPlayerSuggestionsJob).to have_been_enqueued
      end
    end
  end
end
