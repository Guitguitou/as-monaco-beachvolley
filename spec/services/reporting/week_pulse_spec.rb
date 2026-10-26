# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reporting::WeekPulse do
  let(:now) { Time.zone.local(2026, 10, 21, 12) } # un mercredi
  let(:coach) { create(:user, :coach) }

  def metric(key) = described_class.new(now: now).metrics.find { |m| m.key == key }

  def session_on(time, max_players: 10)
    create(:session, user: coach, start_at: time, end_at: time + 1.hour, max_players: max_players)
  end

  it "compare les séances tenues et les inscriptions à la semaine précédente" do
    this_week = session_on(now + 1.day)
    session_on(now - 1.week)
    session_on(now - 1.week + 1.hour)
    create_list(:registration, 4, session: this_week, status: :confirmed)

    sessions = metric(:sessions)
    expect([ sessions.current, sessions.previous, sessions.change, sessions.trend ]).to eq([ 1, 2, -50, :bad ])
    expect(metric(:registrations).current).to eq(4)
    expect(metric(:fill_rate).current).to eq(40)
  end

  it "voit une baisse des désinscriptions tardives comme une bonne nouvelle" do
    late = metric(:late_cancellations).with(current: 1, previous: 3)

    expect(late.trend).to eq(:good)
    expect(metric(:revenue).change).to be_nil
  end
end
