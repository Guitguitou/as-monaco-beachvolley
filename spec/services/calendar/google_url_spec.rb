require "rails_helper"

RSpec.describe Calendar::GoogleUrl do
  let(:event) do
    Ics::Event.new(
      uid: "session-1@asmbv",
      title: "Entraînement, niveau 2",
      starts_at: Time.zone.parse("2026-09-10 18:00"),
      ends_at: Time.zone.parse("2026-09-10 20:00"),
      description: "Apporter de l'eau",
      location: "AS Monaco Beach Volley — Terrain 1",
      url: "https://example.com/sessions/1"
    )
  end

  it "builds a prefilled Google Calendar template URL" do
    uri = URI.parse(described_class.call(event))
    params = Rack::Utils.parse_query(uri.query)

    expect(uri.host).to eq("calendar.google.com")
    expect(params["action"]).to eq("TEMPLATE")
    expect(params["text"]).to eq("Entraînement, niveau 2")
    expect(params["dates"]).to eq("20260910T160000Z/20260910T180000Z")
    expect(params["location"]).to eq("AS Monaco Beach Volley — Terrain 1")
    expect(params["details"]).to eq("Apporter de l'eau\n\nhttps://example.com/sessions/1")
  end

  it "omits blank fields" do
    bare = Ics::Event.new(
      uid: "session-2@asmbv",
      title: "Session",
      starts_at: Time.zone.parse("2026-09-10 18:00"),
      ends_at: Time.zone.parse("2026-09-10 20:00")
    )
    params = Rack::Utils.parse_query(URI.parse(described_class.call(bare)).query)

    expect(params).not_to have_key("details")
    expect(params).not_to have_key("location")
  end
end
