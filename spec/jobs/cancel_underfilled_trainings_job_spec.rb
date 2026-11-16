# frozen_string_literal: true

require "rails_helper"

RSpec.describe CancelUnderfilledTrainingsJob do
  around { |example| travel_to(Time.zone.parse("2035-01-02 15:00")) { example.run } }

  def training(at, players: 0, type: "entrainement")
    create(:session, session_type: type, start_at: Time.zone.parse(at)).tap do |session|
      create_list(:registration, players, session:)
    end
  end

  it "annule les entraînements du jour à moins de 2 inscrits et prévient les inscrits" do
    alone = training("2035-01-02 18:00", players: 1)
    empty = training("2035-01-02 19:30")

    expect { described_class.perform_now }.to have_enqueued_mail(SessionMailer, :session_cancelled).once

    expect(alone.reload).to have_attributes(cancelled?: true, cancellation_reason: "moins_de_2_inscrits")
    expect(empty.reload.cancelled?).to be(true)
  end

  it "garde les entraînements assez remplis, les autres jours, les autres types et ceux déjà commencés" do
    kept = [
      training("2035-01-02 18:00", players: 2),
      training("2035-01-03 18:00", players: 1),
      training("2035-01-02 20:00", type: "jeu_libre"),
      training("2035-01-02 14:00")
    ]

    described_class.perform_now

    expect(kept.map { |session| session.reload.cancelled? }).to all(be(false))
  end
end
