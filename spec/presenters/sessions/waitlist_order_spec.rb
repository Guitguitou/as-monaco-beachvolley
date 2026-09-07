# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::WaitlistOrder do
  let(:monday) { Time.zone.parse("2035-01-01 10:00:00") } # un lundi
  let(:g1) { create(:level, name: "G1", gender: "male") }
  let(:g3) { create(:level, name: "G3", gender: "male") }

  around { |example| travel_to(monday) { example.run } }

  def player
    user = create(:user)
    create(:credit_transaction, user: user, amount: 10_000)
    create(:user_level, user: user, level: g1)
    create(:user_level, user: user, level: g3)
    user
  end

  def training(day_offset:, terrain:, max_players: 1)
    start_at = (monday + 7.days + day_offset.days).change(hour: 19)
    session = create(:session, session_type: "entrainement", terrain: terrain,
                               start_at: start_at, end_at: start_at + 1.hour,
                               max_players: max_players, price: 400,
                               registration_opens_at: monday - 1.day)
    session
  end

  before do
    allow(SendPushNotificationJob).to receive(:perform_later)
    allow(SessionMailer).to receive(:promoted_to_main_list).and_return(double(deliver_later: true))
    allow(SessionMailer).to receive(:displaced_to_waitlist).and_return(double(deliver_later: true))
  end

  it "classe la priorité de groupe avant l'ancienneté" do
    session = training(day_offset: 0, terrain: "Terrain 1")
    create(:session_level, session: session, level: g1, priority: 1)
    create(:session_level, session: session, level: g3, priority: 3)

    holder = create(:registration, user: player, session: session, status: :confirmed)
    late_g1 = player
    early_g3 = player

    # Le G3 arrive d'abord, mais le G1 est plus prioritaire.
    early = create(:registration, :waitlisted, user: early_g3, session: session)
    early.user.user_levels.where(level_id: g1.id).destroy_all
    travel 1.minute
    late = create(:registration, :waitlisted, user: late_g1, session: session)
    late.user.user_levels.where(level_id: g3.id).destroy_all

    expect(described_class.call(session: session).map(&:id)).to eq([ late.id, early.id ])
    expect(holder.reload).to be_confirmed
  end

  it "place le joueur déjà servi cette semaine derrière celui qui ne l'est pas" do
    other = training(day_offset: 0, terrain: "Terrain 1")
    session = training(day_offset: 2, terrain: "Terrain 2")
    [ other, session ].each { |s| create(:session_level, session: s, level: g1, priority: 1) }

    create(:registration, user: player, session: session, status: :confirmed)

    served = player
    create(:registration, user: served, session: other, status: :confirmed)
    early = create(:registration, :waitlisted, user: served, session: session)

    travel 1.minute
    late = create(:registration, :waitlisted, user: player, session: session)

    # `served` est arrivé en premier mais a déjà un entraînement cette semaine.
    expect(described_class.call(session: session).map(&:id)).to eq([ late.id, early.id ])
  end

  it "annonce le même premier candidat que la promotion effective" do
    other = training(day_offset: 0, terrain: "Terrain 1")
    session = training(day_offset: 2, terrain: "Terrain 2")
    [ other, session ].each { |s| create(:session_level, session: s, level: g1, priority: 1) }

    holder = create(:registration, user: player, session: session, status: :confirmed)

    served = player
    create(:registration, user: served, session: other, status: :confirmed)
    create(:registration, :waitlisted, user: served, session: session)
    travel 1.minute
    fresh = create(:registration, :waitlisted, user: player, session: session)

    expected_first = described_class.call(session: session).first
    holder.destroy!
    promoted = Sessions::WaitlistPromotionService.call(session: session)

    expect(expected_first.id).to eq(fresh.id)
    expect(promoted.id).to eq(expected_first.id)
  end
end
