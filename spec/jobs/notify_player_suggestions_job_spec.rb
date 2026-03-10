# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotifyPlayerSuggestionsJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    before do
      ActiveJob::Base.queue_adapter = :test
      clear_enqueued_jobs
    end

    context "when a newly created listing matches another player availability" do
      let(:level) { create(:level) }
      let(:author) { create(:user, activated_at: Time.current) }
      let(:target_user) { create(:user, activated_at: Time.current) }
      let!(:target_subscription) { create(:push_subscription, user: target_user) }
      let!(:author_listing) do
        create(
          :player_listing,
          user: author,
          listing_type: "disponible",
          date: Date.new(2026, 2, 27),
          starts_at: Time.zone.parse("10:00"),
          ends_at: Time.zone.parse("12:00")
        )
      end

      before do
        author_listing.levels << level

        candidate_listing = create(
          :player_listing,
          user: target_user,
          listing_type: "recherche",
          date: Date.new(2026, 2, 27),
          starts_at: Time.zone.parse("11:00"),
          ends_at: Time.zone.parse("12:30")
        )
        candidate_listing.levels << level
      end

      it "records a targeted suggestion and enqueues a push delivery" do
        expect {
          described_class.perform_now(event_type: "listing_created", listing_id: author_listing.id)
        }.to change(PlayerSuggestionNotification, :count).by(1)

        expect(SendPushNotificationJob).to have_been_enqueued
      end
    end
  end
end
