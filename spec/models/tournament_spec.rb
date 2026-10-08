# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tournament do
  it "refuse un niveau inconnu" do
    expect(build(:tournament, level: "S9")).not_to be_valid
  end

  it "refuse une fin avant le début" do
    expect(build(:tournament, end_time: "09:00")).not_to be_valid
  end

  it "met en avant le prochain tournoi, jusqu'au jour J inclus" do
    create(:tournament, starts_on: Date.yesterday, ends_on: Date.yesterday)
    today = create(:tournament, starts_on: Date.current, ends_on: Date.current)
    create(:tournament, starts_on: Date.current + 1.month)

    expect(described_class.featured).to eq(today)
  end

  it "affiche le niveau avec ses points" do
    expect(build(:tournament, level: "S3", points: 150).level_label).to eq("S3 · 150")
  end

  describe "#paid_by?" do
    let(:tournament) { build(:tournament) }
    let(:user) { create(:user) }

    before { Tournaments::Save.new(tournament: tournament, owner: create(:user, :admin)).call }

    it "est vrai seulement après un paiement réussi" do
      create(:credit_purchase, user: user, pack: tournament.pack, amount_cents: 3000, status: :pending)
      expect(tournament.paid_by?(user)).to be(false)

      create(:credit_purchase, user: user, pack: tournament.pack, amount_cents: 3000, status: :paid)
      expect(tournament.paid_by?(user)).to be(true)
    end
  end

  describe "images" do
    let(:tournament) { create(:tournament) }

    before do
      %w[a b c].each do |name|
        tournament.images.attach(io: StringIO.new(name), filename: "#{name}.png", content_type: "image/png")
      end
    end

    it "prend la première image comme couverture et suit l'ordre choisi" do
      first, second, third = tournament.ordered_images
      expect(tournament.cover_image).to eq(first)

      tournament.reorder_images([ first.id, third.id, second.id, 999 ])
      expect(tournament.reload.ordered_images).to eq([ first, third, second ])
    end
  end
end
