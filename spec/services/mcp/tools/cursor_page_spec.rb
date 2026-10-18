# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mcp::Tools::CursorPage do
  let!(:users) do
    base = Time.zone.parse("2026-10-01 10:00")
    [ base, base, base + 1.hour ].map { |updated_at| create(:user).tap { |user| user.update_columns(updated_at:) } }
  end

  def page(**options) = described_class.new(User.where(id: users.map(&:id)), per_page: 2, **options).call

  it "parcourt toutes les pages dans l'ordre updated_at, id, sans doublon" do
    first = page
    second = page(cursor: first[:next_cursor])

    ids = (first[:records] + second[:records]).map(&:id)
    expect(ids).to eq(users.sort_by { |user| [ user.updated_at, user.id ] }.map(&:id))
    expect(second[:next_cursor]).to be_nil
  end

  it "ne renvoie pas de curseur quand tout tient sur une page" do
    expect(described_class.new(User.where(id: users.first.id), per_page: 2).call[:next_cursor]).to be_nil
  end

  it "filtre sur updated_since (inclus)" do
    result = page(updated_since: "2026-10-01T11:00:00+02:00")

    expect(result[:records]).to eq([ users.last ])
  end

  it "refuse un curseur ou une date invalides" do
    expect { page(cursor: "n'importe quoi") }.to raise_error(ArgumentError, /Curseur invalide/)
    expect { page(updated_since: "hier") }.to raise_error(ArgumentError, /Date invalide/)
  end
end
