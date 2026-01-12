# frozen_string_literal: true

require "rails_helper"

RSpec.describe SendPushNotificationJob, type: :job do
  let(:user) { create(:user) }

  before do
    allow(PushNotificationService).to receive(:send_to_user)
  end

  it "calls PushNotificationService with correct parameters" do
    described_class.perform_now(
      user.id,
      title: "Test Title",
      body: "Test Body",
      url: "/test"
    )

    expect(PushNotificationService).to have_received(:send_to_user).with(
      user,
      title: "Test Title",
      body: "Test Body",
      url: "/test",
      icon: nil
    )
  end

  it "handles missing user gracefully" do
    expect {
      described_class.perform_now(999_999, title: "Test", body: "Test")
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
