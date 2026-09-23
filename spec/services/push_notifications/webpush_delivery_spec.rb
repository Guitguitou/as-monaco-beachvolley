# frozen_string_literal: true

require "rails_helper"

RSpec.describe PushNotifications::WebpushDelivery do
  let(:subscription) { create(:push_subscription) }
  let(:delivery) do
    described_class.new(vapid: { subject: "mailto:club@example.com", public_key: "pub", private_key: "priv" },
                        default_icon: "/logo.png", default_url: "https://club.example/")
  end
  let(:webpush_response) { instance_double(Net::HTTPResponse, body: "", code: "410") }

  it "sends the notification to the subscription, signed with the VAPID keys" do
    allow(Webpush).to receive(:payload_send)

    delivery.call(subscription, title: "Salut", body: "Session demain", url: "/sessions/1")

    expect(Webpush).to have_received(:payload_send).with(
      message: { title: "Salut", body: "Session demain", icon: "/logo.png", badge: "/logo.png", data: { url: "/sessions/1" } }.to_json,
      endpoint: subscription.endpoint, p256dh: subscription.p256dh, auth: subscription.auth,
      vapid: { subject: "mailto:club@example.com", public_key: "pub", private_key: "priv" }
    )
  end

  it "opens the app home when no url is given" do
    allow(Webpush).to receive(:payload_send)

    delivery.call(subscription, title: "Salut", body: "Hello", icon: "/custom.png")

    expect(Webpush).to have_received(:payload_send).with(hash_including(message: include('"icon":"/custom.png"', '"url":"https://club.example/"')))
  end

  it "forgets a subscription the browser no longer accepts" do
    allow(Webpush).to receive(:payload_send).and_raise(Webpush::ExpiredSubscription.new(webpush_response, "fcm.googleapis.com"))

    expect { delivery.call(subscription, title: "Salut", body: "Hello") }.not_to raise_error
    expect(PushSubscription.exists?(subscription.id)).to be(false)
  end

  it "lets the other failures through" do
    allow(Webpush).to receive(:payload_send).and_raise(Webpush::ResponseError.new(webpush_response, "fcm.googleapis.com"))

    expect { delivery.call(subscription, title: "Salut", body: "Hello") }.to raise_error(Webpush::ResponseError)
  end
end
