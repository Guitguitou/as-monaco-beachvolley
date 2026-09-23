# frozen_string_literal: true

require "rails_helper"

RSpec.describe PushNotifications::EventRouting do
  let(:routes) { Rails.application.routes.url_helpers }
  let(:session_record) { create(:session) }

  it "sends session news to every activated member, towards the session" do
    active = create(:user, activated_at: Time.current)
    inactive = create(:user, activated_at: nil)
    routing = described_class.new("session_created", { session: session_record })

    expect(routing.users).to include(active)
    expect(routing.users).not_to include(inactive)
    expect(routing.url).to eq(routes.session_path(session_record))
    expect(described_class.new("session_cancelled", {}).url).to eq(routes.sessions_path)
  end

  it "sends a registration update to the registered player only" do
    player = create(:user)
    routing = described_class.new("registration_confirmed", { user: player })

    expect(routing.users).to eq([ player ])
    expect(routing.url).to eq(routes.me_sessions_path)
  end

  it "sends the low credit warning to activated members short of credits, towards the shop" do
    routing = described_class.new("credit_low", {})

    expect(routing.url).to eq(routes.packs_path)
    expect(routing.users.to_sql).to include("balances")
  end

  it "points stage news to the stage" do
    expect(described_class.new("stage_created", {}).url).to eq(routes.stages_path)
  end

  it "reaches nobody for an unknown event" do
    routing = described_class.new("inconnu", {})

    expect([ routing.users.to_a, routing.url ]).to eq([ [], routes.root_path ])
  end
end
