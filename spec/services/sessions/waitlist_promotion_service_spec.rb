# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::WaitlistPromotionService, type: :service do
  let(:monday) { Time.zone.parse("2035-01-01 10:00:00") } # un lundi
  let(:level) { create(:level) }

  around { |example| travel_to(monday) { example.run } }

  def player(credits: 10_000)
    user = create(:user)
    create(:credit_transaction, user: user, amount: credits)
    create(:user_level, user: user, level: level)
    user
  end

  def training(day_offset:, terrain:, max_players: 1)
    start_at = (monday + 7.days + day_offset.days).change(hour: 19)
    session = create(:session, session_type: "entrainement", terrain: terrain,
                               start_at: start_at, end_at: start_at + 1.hour,
                               max_players: max_players, price: 400,
                               registration_opens_at: monday - 1.day)
    create(:session_level, session: session, level: level, priority: 1)
    session
  end

  before do
    allow(SendPushNotificationJob).to receive(:perform_later)
    allow(SessionMailer).to receive(:promoted_to_main_list).and_return(double(deliver_later: true))
  end

  it "promeut d'abord le joueur qui n'a pas encore d'entraînement cette semaine" do
    other = training(day_offset: 0, terrain: "Terrain 1")
    session = training(day_offset: 2, terrain: "Terrain 2")

    served = player
    create(:registration, user: served, session: other, status: :confirmed)
    early = create(:registration, :waitlisted, user: served, session: session)

    travel 1.minute
    late = create(:registration, :waitlisted, user: player, session: session)

    promoted = described_class.call(session: session)

    expect(promoted.id).to eq(late.id)
    expect(early.reload).to be_waitlisted
  end

  it "accepte un résolveur déjà chargé sans requête de priorité supplémentaire" do
    session = training(day_offset: 2, terrain: "Terrain 2")
    registration = create(:registration, :waitlisted, user: player, session: session)

    resolver = Registrations::WeeklyPriorityResolver.new(session: session)
    resolver.prime([ registration ])

    expect(Registrations::WeeklyConfirmedTrainingsQuery).not_to receive(:call)
    expect(described_class.call(session: session, weekly_priority: resolver).id).to eq(registration.id)
  end
end
