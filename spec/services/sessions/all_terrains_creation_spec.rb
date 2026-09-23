# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::AllTerrainsCreation do
  let(:coach) { create(:user, :coach) }
  let(:start_at) { 3.days.from_now.change(hour: 18) }
  let(:attributes) do
    { "title" => "Jeu libre", "session_type" => "jeu_libre", "user_id" => coach.id, "terrain" => "Terrain 2",
      "start_at" => start_at, "end_at" => start_at + 90.minutes }
  end

  it "creates the same session on every terrain, whatever terrain was picked" do
    created = []

    errors = described_class.new(attributes).call { |session| created << session }

    expect(errors).to be_empty
    expect(Session.where(start_at: start_at).pluck(:terrain)).to contain_exactly("Terrain 1", "Terrain 2", "Terrain 3")
    expect(created.map(&:terrain)).to eq([ "Terrain 1", "Terrain 2", "Terrain 3" ])
  end

  it "creates nothing when one terrain is taken" do
    create(:session, user: coach, terrain: "Terrain 3", start_at: start_at, end_at: start_at + 1.hour)

    errors = described_class.new(attributes).call { |_session| }

    expect(errors).to contain_exactly(include("déjà pris"))
    expect(Session.where(start_at: start_at).count).to eq(1)
  end
end
