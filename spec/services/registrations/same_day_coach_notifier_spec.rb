# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registrations::SameDayCoachNotifier do
  let(:coach) { create(:user, :coach) }
  let(:player) { create(:user, first_name: "Léa", last_name: "Martin") }
  let(:today_evening) { Time.current.change(hour: 19) }

  before do
    travel_to Time.current.change(hour: 12)
    allow(SendPushNotificationJob).to receive(:perform_later)
  end

  def training(start_at: today_evening, **attrs)
    create(:session, user: coach, start_at: start_at, end_at: start_at + 90.minutes, **attrs)
  end

  def notify(session, user: player, status: :confirmed, promoted: false)
    described_class.new(Registration.new(user: user, session: session, status: status), promoted: promoted).call
  end

  it "prévient le coach d'une inscription le jour même à son entraînement" do
    session = training

    notify(session)

    expect(SendPushNotificationJob).to have_received(:perform_later).with(
      coach.id,
      title: "Inscription de dernière minute 🏐",
      body: "Léa Martin vient de s'inscrire à Session de test aujourd'hui à 19:00",
      url: "/sessions/#{session.id}"
    )
  end

  it "prévient le coach d'une promotion depuis la liste d'attente le jour même" do
    notify(training, promoted: true)

    expect(SendPushNotificationJob).to have_received(:perform_later).with(
      coach.id,
      hash_including(body: "Léa Martin passe de la liste d'attente à la liste principale de Session de test aujourd'hui à 19:00")
    )
  end

  it "ne prévient pas pour un entraînement d'un autre jour" do
    notify(training(start_at: 1.day.from_now.change(hour: 19)))

    expect(SendPushNotificationJob).not_to have_received(:perform_later)
  end

  it "ne prévient pas pour une session qui n'est pas un entraînement" do
    notify(training(session_type: "jeu_libre"))

    expect(SendPushNotificationJob).not_to have_received(:perform_later)
  end

  it "ne prévient pas pour une mise en liste d'attente" do
    notify(training, status: :waitlisted)

    expect(SendPushNotificationJob).not_to have_received(:perform_later)
  end

  it "ne prévient pas le coach qui s'inscrit à sa propre session" do
    notify(training, user: coach)

    expect(SendPushNotificationJob).not_to have_received(:perform_later)
  end
end
