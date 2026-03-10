# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayerSuggestionPushService, type: :service do
  include ActiveJob::TestHelper

  describe ".notify_user" do
    let(:user) { create(:user, activated_at: Time.current, player_suggestions_push_enabled: true) }
    let(:base_params) do
      {
        user: user,
        event_type: "session_opened",
        fingerprint: "session-42-user-#{user.id}",
        title: "Nouvelle session ouverte",
        body: "Session ouverte ce soir.",
        url: "/player_listings"
      }
    end

    before do
      ActiveJob::Base.queue_adapter = :test
      clear_enqueued_jobs
    end

    context "when the user opted in and has no recent notifications" do
      it "enqueues a push and stores a notification trace" do
        expect { described_class.notify_user(**base_params) }
          .to change(PlayerSuggestionNotification, :count).by(1)

        expect(SendPushNotificationJob).to have_been_enqueued
      end
    end

    context "when the user opted out from suggestion notifications" do
      before do
        user.update!(player_suggestions_push_enabled: false)
      end

      it "skips the push to respect the preference" do
        expect { described_class.notify_user(**base_params) }
          .not_to change(PlayerSuggestionNotification, :count)

        expect(SendPushNotificationJob).not_to have_been_enqueued
      end
    end

    context "when the same fingerprint was already sent recently" do
      before do
        described_class.notify_user(**base_params)
        clear_enqueued_jobs
      end

      it "does not send a duplicate notification" do
        expect { described_class.notify_user(**base_params) }
          .not_to change(PlayerSuggestionNotification, :count)

        expect(SendPushNotificationJob).not_to have_been_enqueued
      end
    end

    context "when the user already received too many notifications recently" do
      before do
        3.times do |i|
          described_class.notify_user(**base_params.merge(fingerprint: "session-#{i}-#{user.id}"))
        end
        clear_enqueued_jobs
      end

      it "does not enqueue extra notifications to prevent spam" do
        expect { described_class.notify_user(**base_params.merge(fingerprint: "session-extra-#{user.id}")) }
          .not_to change(PlayerSuggestionNotification, :count)

        expect(SendPushNotificationJob).not_to have_been_enqueued
      end
    end
  end
end
