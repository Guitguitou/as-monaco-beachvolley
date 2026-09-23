# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::TypeDefaults do
  let(:start_at) { Time.zone.local(2030, 3, 14, 19, 0) }

  it "prices the session from its type, whatever was typed" do
    session = Session.new(session_type: "entrainement", price: 1)

    described_class.apply(session)

    expect(session.price).to eq(Session::TRAINING_PRICE)
    expect(described_class.apply(Session.new(session_type: "tournoi")).price).to eq(0)
  end

  it "opens a training 7 days before and closes cancellations at 22h the day before" do
    session = described_class.apply(Session.new(session_type: "entrainement", start_at: start_at))

    expect(session.registration_opens_at).to eq(start_at - 7.days)
    expect(session.cancellation_deadline_at).to eq(Time.zone.local(2030, 3, 13, 22, 0))
  end

  it "keeps the dates set by hand" do
    opens = start_at - 2.days
    deadline = start_at - 3.hours
    session = described_class.apply(Session.new(session_type: "entrainement", start_at: start_at,
                                                registration_opens_at: opens, cancellation_deadline_at: deadline))

    expect([ session.registration_opens_at, session.cancellation_deadline_at ]).to eq([ opens, deadline ])
  end

  it "has no opening date nor cancellation deadline outside trainings" do
    session = described_class.apply(Session.new(session_type: "jeu_libre", start_at: start_at, registration_opens_at: start_at - 1.day))

    expect([ session.registration_opens_at, session.cancellation_deadline_at ]).to eq([ nil, nil ])
  end
end
