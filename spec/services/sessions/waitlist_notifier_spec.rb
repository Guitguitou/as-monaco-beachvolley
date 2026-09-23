# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::WaitlistNotifier do
  let(:session_record) { create(:session, title: "Entraînement G1", start_at: Time.zone.local(2030, 3, 14, 19, 30), end_at: Time.zone.local(2030, 3, 14, 21)) }
  let(:user) { create(:user) }
  let(:notifier) { described_class.new(session_record) }
  let(:mail) { double(deliver_later: true) }

  before { allow(SendPushNotificationJob).to receive(:perform_later) }

  it "tells a promoted player why, by push and mail" do
    allow(SessionMailer).to receive(:promoted_to_main_list).and_return(mail)

    notifier.promoted(user, cause: "Une place s'est libérée pour la session")

    expect(SendPushNotificationJob).to have_received(:perform_later).with(
      user.id,
      title: "Tu passes en liste principale !",
      body: "Une place s'est libérée pour la session Entraînement G1 du 14/03/2030 à 19h30, tu viens de passer en liste principale",
      url: "/sessions/#{session_record.id}"
    )
    expect(SessionMailer).to have_received(:promoted_to_main_list).with(user, session_record)
    expect(mail).to have_received(:deliver_later)
  end

  it "tells a displaced player they are back on the waitlist, by push and mail" do
    allow(SessionMailer).to receive(:displaced_to_waitlist).and_return(mail)

    notifier.displaced(user)

    expect(SendPushNotificationJob).to have_received(:perform_later).with(
      user.id, hash_including(title: "Tu repasses en liste d'attente", body: start_with("Un joueur prioritaire s'est inscrit à Entraînement G1 du 14/03/2030 à 19h30"))
    )
    expect(SessionMailer).to have_received(:displaced_to_waitlist).with(user, session_record)
  end

  it "tells a waitlisted player they lack credits, by push only" do
    notifier.insufficient_credits(user)

    expect(SendPushNotificationJob).to have_received(:perform_later).with(
      user.id, hash_including(title: "Pas assez de crédits", body: "Tu n'as pas assez de crédits pour passer en liste principale.")
    )
  end

  it "does not let a failing notification break the caller" do
    allow(SendPushNotificationJob).to receive(:perform_later).and_raise("queue down")

    expect { notifier.insufficient_credits(user) }.not_to raise_error
  end
end
