# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::MobileAgenda do
  let(:player) { create(:user) }
  let(:events) do
    [
      { id: 1, start: "2030-03-13T20:00:00+01:00", status: "open" },
      { id: 2, start: "2030-03-13T18:00:00+01:00", status: "registered" },
      { id: 3, start: "2030-03-16T19:00:00+01:00", status: "unavailable" }
    ]
  end
  let(:agenda) { described_class.new(events: events, user: player, date_param: "2030-03-13") }

  it "shows the seven days of the week with one dot per session" do
    week = agenda.week

    expect(week.map(&:date)).to eq((Date.new(2030, 3, 11)..Date.new(2030, 3, 17)).to_a)
    expect(week[2].statuses).to eq(%w[registered open])
    expect(week[5].statuses).to eq(%w[unavailable])
  end

  it "lists the sessions of the chosen day in time order" do
    expect(agenda.events_of_day.pluck(:id)).to eq([ 2, 1 ])
  end

  it "falls back to today without a readable date" do
    expect(described_class.new(events: [], user: player, date_param: "nope").day).to eq(Time.zone.today)
  end

  it "lists the player's upcoming registrations" do
    start_at = 2.days.from_now.change(hour: 19)
    session = create(:session, :jeu_libre, start_at: start_at, end_at: start_at + 90.minutes)
    registration = create(:registration, user: player, session: session, status: :waitlisted)

    expect(agenda.upcoming).to eq([ registration ])
  end
end
