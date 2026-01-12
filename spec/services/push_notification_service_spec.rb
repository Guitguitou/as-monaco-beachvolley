# frozen_string_literal: true

require "rails_helper"

RSpec.describe PushNotificationService, type: :service do
  let(:user) { create(:user) }
  let(:subscription) { create(:push_subscription, user: user) }

  before do
    # Mock VAPID keys
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return("test_public_key")
    allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return("test_private_key")
    allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return("mailto:test@example.com")

    # Mock Rails routes
    allow(Rails.application.routes.url_helpers).to receive(:root_path).and_return("/")
    allow(Rails.application.routes.url_helpers).to receive(:root_url).and_return("http://test.host/")
    allow(Rails.application.routes.url_helpers).to receive(:session_path).and_return("/sessions/1")
    allow(Rails.application.routes.url_helpers).to receive(:packs_path).and_return("/packs")
    allow(Rails.application.routes.url_helpers).to receive(:sessions_path).and_return("/sessions")
    allow(ActionController::Base.helpers).to receive(:asset_url).and_return(nil)
  end

  describe ".send_to_user" do
    context "when user has subscriptions" do
      before { subscription }

      it "sends notification to all user subscriptions" do
        expect(Webpush).to receive(:payload_send).once
        described_class.send_to_user(
          user,
          title: "Test Title",
          body: "Test Body",
          url: "/test"
        )
      end

      it "handles invalid subscriptions gracefully" do
        allow(Webpush).to receive(:payload_send).and_raise(Webpush::InvalidSubscription.new("Invalid"))
        expect { described_class.send_to_user(user, title: "Test", body: "Test") }.not_to raise_error
        expect(user.push_subscriptions.reload).to be_empty
      end

      it "handles expired subscriptions gracefully" do
        allow(Webpush).to receive(:payload_send).and_raise(Webpush::ExpiredSubscription.new("Expired"))
        expect { described_class.send_to_user(user, title: "Test", body: "Test") }.not_to raise_error
        expect(user.push_subscriptions.reload).to be_empty
      end
    end

    context "when user has no subscriptions" do
      it "does not send any notifications" do
        expect(Webpush).not_to receive(:payload_send)
        described_class.send_to_user(user, title: "Test", body: "Test")
      end
    end
  end

  describe ".send_to_users" do
    let(:user2) { create(:user) }
    let!(:subscription2) { create(:push_subscription, user: user2) }

    before { subscription }

    it "sends notifications to multiple users" do
      expect(Webpush).to receive(:payload_send).twice
      described_class.send_to_users(
        User.where(id: [user.id, user2.id]),
        title: "Test Title",
        body: "Test Body"
      )
    end
  end

  describe ".send_for_event" do
    let(:session_record) { create(:session, title: "Test Session") }
    let!(:rule) do
      create(:notification_rule,
             event_type: "session_created",
             title_template: "New: {{session_name}}",
             body_template: "Date: {{session_date}}",
             enabled: true)
    end

    before do
      allow(described_class).to receive(:send_to_user)
    end

    it "sends notifications based on matching rules" do
      context = {
        session: session_record,
        session_name: session_record.title,
        session_date: session_record.start_at.strftime("%d/%m/%Y")
      }
      described_class.send_for_event("session_created", context: context)
      expect(described_class).to have_received(:send_to_user).at_least(:once)
    end

    it "does not send when no rules match" do
      described_class.send_for_event("nonexistent_event", context: {})
      expect(described_class).not_to have_received(:send_to_user)
    end

    it "does not send when rule is disabled" do
      rule.update(enabled: false)
      context = { session: session_record }
      described_class.send_for_event("session_created", context: context)
      expect(described_class).not_to have_received(:send_to_user)
    end
  end
end
