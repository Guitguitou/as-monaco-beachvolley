# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SessionsTab do
  let(:coach) { create(:user, :coach) }
  let(:now) { Time.find_zone("Europe/Paris").local(2030, 3, 13, 12) }

  before { travel_to(now) }
  after { travel_back }

  def tab(params)
    described_class.new(ActionController::Parameters.new(params))
  end

  it "shows the upcoming sessions by default, soonest first" do
    later = create(:session, user: coach, start_at: now + 2.days, end_at: now + 2.days + 1.hour)
    sooner = create(:session, :jeu_libre, user: coach, start_at: now + 1.day, end_at: now + 1.day + 1.hour)
    create(:session, user: coach, start_at: now - 1.day, end_at: now - 1.day + 1.hour)

    expect(tab({}).sub_tab).to eq("upcoming")
    expect(tab({}).upcoming_sessions.to_a).to eq([ sooner, later ])
  end

  it "lists one type of session over the chosen period, latest first" do
    first = create(:session, user: coach, start_at: now + 1.hour, end_at: now + 2.hours)
    second = create(:session, user: coach, start_at: now + 1.day, end_at: now + 1.day + 1.hour)
    create(:session, :jeu_libre, user: coach, start_at: now + 2.hours, end_at: now + 3.hours)
    create(:session, user: coach, start_at: now + 8.days, end_at: now + 8.days + 1.hour)

    week = tab(session_type: "entrainement", period: "week")

    expect(week.sessions_by_type.to_a).to eq([ second, first ])
    expect(week.period.name).to eq("week")
    expect(week.previous_period_params).to eq({ tab: "sessions", session_type: "entrainement", period: "week", period_anchor: "2030-03-04" })
    expect(week.next_period_params[:period_anchor]).to eq("2030-03-18")
  end

  it "keeps every type for an unknown one" do
    create(:session, :tournoi, user: coach, start_at: now + 1.hour, end_at: now + 2.hours)
    create(:session, :jeu_libre, user: coach, start_at: now + 3.hours, end_at: now + 4.hours)

    expect(tab(session_type: "tous", period: "month").sessions_by_type.count).to eq(2)
    expect(tab(session_type: "tournoi", period: "month").sessions_by_type.count).to eq(1)
  end
end
