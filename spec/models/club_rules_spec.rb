# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClubRules do
  subject(:rules) { described_class.current }

  it "holds the club values" do
    expect(rules.price_by_type).to eq("entrainement" => 400, "jeu_libre" => 300, "coaching_prive" => 1500, "stage" => 0)
    expect([ rules.priority_window_hours, rules.registration_deadline_hour ]).to eq([ 24, 17 ])
    expect([ rules.registration_opening_days, rules.cancellation_deadline_hour ]).to eq([ 7, 22 ])
    expect(rules.time_zone).to eq("Europe/Paris")
  end

  it "is a frozen shared instance" do
    expect(rules).to be_frozen
    expect(rules.price_by_type).to be_frozen
    expect(described_class.current).to equal(rules)
  end

  it "prices a session type, 0 for an unknown one" do
    expect(rules.price_for(:coaching_prive)).to eq(1500)
    expect(rules.price_for("tournoi")).to eq(0)
  end

  it "derives the registration dates from a start time" do
    start_at = Time.zone.local(2030, 3, 14, 19, 0)

    expect(rules.registration_opens_at_for(start_at)).to eq(Time.zone.local(2030, 3, 7, 19, 0))
    expect(rules.cancellation_deadline_for(start_at)).to eq(Time.zone.local(2030, 3, 13, 22, 0))
    expect(rules.registration_deadline_for(start_at)).to eq(Time.zone.local(2030, 3, 14, 17, 0))
    expect(rules.priority_ends_at(start_at)).to eq(start_at + 24.hours)
  end

  it "accepts other values" do
    other = described_class.default.with(price_by_type: { jeu_libre: 500 }, time_zone: "Europe/London")

    expect(other.price_for("jeu_libre")).to eq(500)
    expect(other.zone.name).to eq("Europe/London")
  end

  it "computes the cancellation deadline in both modes" do
    start_at = Time.zone.local(2030, 3, 14, 19, 0)
    hours_before = described_class.default.with(cancellation_deadline_mode: "hours_before", cancellation_hours_before: 10)

    expect(described_class.default.cancellation_deadline_for(start_at)).to eq(Time.zone.local(2030, 3, 13, 22, 0))
    expect(hours_before.cancellation_deadline_for(start_at)).to eq(Time.zone.local(2030, 3, 14, 9, 0))
  end

  it "matches the default rules with the club's initial settings" do
    expect(rules).to eq(described_class.default)
  end

  it "reflects saved settings within the same request" do
    expect(rules.registration_deadline_hour).to eq(17)

    ClubSetting.current.update!(registration_deadline_hour: 15, jeu_libre_price_cents: 450)

    expect(described_class.current.registration_deadline_hour).to eq(15)
    expect(described_class.current.price_for("jeu_libre")).to eq(450)
  end
end
