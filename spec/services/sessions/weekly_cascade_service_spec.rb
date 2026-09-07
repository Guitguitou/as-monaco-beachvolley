# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::WeeklyCascadeService, type: :service do
  let(:monday) { Time.zone.parse("2035-01-01 10:00:00") } # un lundi
  let(:level) { create(:level) }

  around { |example| travel_to(monday) { example.run } }

  def player(credits: 10_000)
    user = create(:user)
    create(:credit_transaction, user: user, amount: credits)
    create(:user_level, user: user, level: level)
    user
  end

  def training(day_offset:, terrain:, week_offset: 7, max_players: 1)
    start_at = (monday + week_offset.days + day_offset.days).change(hour: 19)
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
    allow(SessionMailer).to receive(:displaced_to_waitlist).and_return(double(deliver_later: true))
  end

  it "repromeut le joueur redevenu prioritaire sur ses autres entraînements de la semaine" do
    s1 = training(day_offset: 0, terrain: "Terrain 1")
    s2 = training(day_offset: 2, terrain: "Terrain 2")

    user = player
    reg1 = create(:registration, user: user, session: s1, status: :confirmed)
    travel 1.minute
    reg2 = create(:registration, user: user, session: s2, status: :confirmed)

    travel 1.minute
    rival = create(:registration, user: player, session: s2, status: :waitlisted)
    Sessions::PriorityBalancerService.call(session: s2)

    expect(reg2.reload).to be_waitlisted # déclassé : 2e entraînement de la semaine
    expect(rival.reload).to be_confirmed

    # Il libère sa 1re place : sa 2e inscription redevient prioritaire.
    rival.destroy!
    reg1.destroy!

    described_class.call(user: user, session: s1)

    expect(reg2.reload).to be_confirmed
  end

  it "ne fait rien sur la semaine en cours" do
    current = training(day_offset: 1, terrain: "Terrain 1", week_offset: 0)

    expect(Sessions::PriorityBalancerService).not_to receive(:call)
    described_class.call(user: player, session: current)
  end

  it "ne fait rien pour une session qui n'est pas un entraînement" do
    start_at = (monday + 8.days).change(hour: 19)
    libre = create(:session, :jeu_libre, terrain: "Terrain 3",
                             start_at: start_at, end_at: start_at + 1.hour)

    expect(Sessions::PriorityBalancerService).not_to receive(:call)
    described_class.call(user: player, session: libre)
  end
end
