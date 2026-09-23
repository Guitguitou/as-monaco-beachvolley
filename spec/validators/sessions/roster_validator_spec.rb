# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::RosterValidator do
  let(:session_record) { build(:session, max_players: 2) }
  let(:player) { create(:user) }

  def validate
    described_class.new.validate(session_record)
    session_record.errors[:registrations]
  end

  it "accepts distinct players within the places" do
    session_record.registrations.build(user: player, status: :confirmed)

    expect(validate).to be_empty
  end

  it "rejects the same player twice" do
    2.times { session_record.registrations.build(user: player, status: :waitlisted) }

    expect(validate).to include("ne peut participer qu'une seule fois à une session")
  end

  it "ignores a registration being removed" do
    session_record.registrations.build(user: player, status: :waitlisted)
    session_record.registrations.build(user: player, status: :waitlisted).mark_for_destruction

    expect(validate).to be_empty
  end

  it "rejects more confirmed players than places" do
    3.times { session_record.registrations.build(user: create(:user), status: :confirmed) }

    expect(validate).to include("le nombre de participants ne peut pas dépasser 2")
  end
end
