# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::ScheduleValidator do
  let(:coach) { create(:user, :coach) }
  let(:start_at) { 5.days.from_now.change(hour: 18) }

  def session_at(start, finish, terrain: "Terrain 1")
    build(:session, user: coach, start_at: start, end_at: finish, terrain: terrain)
  end

  def validate(session)
    described_class.new.validate(session)
    session.errors
  end

  it "accepts a free slot" do
    expect(validate(session_at(start_at, start_at + 1.hour))).to be_empty
  end

  it "rejects an end before the start" do
    expect(validate(session_at(start_at, start_at - 1.hour))[:end_at]).to include("doit être après la date de début")
  end

  it "rejects a slot already taken on the same terrain" do
    create(:session, user: coach, start_at: start_at, end_at: start_at + 2.hours)

    errors = validate(session_at(start_at + 1.hour, start_at + 3.hours))

    expect(errors[:terrain]).to include("est déjà pris sur ce créneau")
    expect(errors[:base]).to include("Une session existe déjà sur ce terrain pendant ces horaires")
    expect(validate(session_at(start_at + 1.hour, start_at + 3.hours, terrain: "Terrain 2"))).to be_empty
  end

  it "rejects a closed terrain" do
    allow(TerrainClosure).to receive(:covers?).with(terrain: "Terrain 1", date: start_at.to_date).and_return(true)

    expect(validate(session_at(start_at, start_at + 1.hour))[:terrain]).to include("est indisponible à cette date (fermeture ou maintenance)")
  end

  it "leaves incomplete sessions to the presence validations" do
    expect(validate(session_at(nil, nil))).to be_empty
  end
end
