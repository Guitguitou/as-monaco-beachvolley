# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Tables::Sessions do
  let(:coach) { create(:user, :coach) }
  let!(:past) { create(:session, user: coach, title: "Passé", start_at: 3.days.ago, end_at: 3.days.ago + 1.hour) }
  let!(:tournament) { create(:session, :tournoi, user: coach, title: "Open", start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour) }

  def filter(params)
    DataTable::Query.call(relation: Session.all, definition: described_class.new,
                          state: DataTable::State.new(ActionController::Parameters.new(params))).to_a
  end

  it "trie par date décroissante par défaut" do
    expect(filter({})).to eq([ tournament, past ])
  end

  it "filtre par type, par date et par statut" do
    expect(filter(f: { session_type: "tournoi" })).to eq([ tournament ])
    expect(filter(f: { start_at: { from: Date.current.iso8601 } })).to eq([ tournament ])
    past.update_columns(cancelled_at: Time.current)
    expect(filter(f: { status: "cancelled" })).to eq([ past ])
  end

  it "propose les séances à venir en filtre rapide" do
    expect(filter(quick: "upcoming")).to eq([ tournament ])
  end

  it "résume les niveaux au-delà de trois" do
    session = build(:session, levels: build_list(:level, 5))

    expect(described_class.new.levels_label(session)).to match(/\A[^,]+, [^,]+, [^,]+ \+2\z/)
  end
end
