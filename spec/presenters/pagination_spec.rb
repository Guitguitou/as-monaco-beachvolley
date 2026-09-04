# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pagination do
  let(:user) { create(:user) }

  # CreditTransaction est le cas d'usage réel (historique du profil).
  def create_transactions(count)
    count.times do |i|
      create(:credit_transaction, user: user, amount: i + 1, transaction_type: :purchase)
    end
  end

  describe "with fewer records than a page" do
    before { create_transactions(3) }

    subject(:page) { described_class.new(scope: user.credit_transactions, page: nil) }

    it "returns everything on a single page" do
      expect(page.records.size).to eq(3)
      expect(page.total_count).to eq(3)
      expect(page.total_pages).to eq(1)
      expect(page.current_page).to eq(1)
      expect(page).not_to be_multiple_pages
      expect(page.next_page).to be_nil
      expect(page.prev_page).to be_nil
    end
  end

  describe "with several pages" do
    before { create_transactions(5) }

    it "slices the scope" do
      first = described_class.new(scope: user.credit_transactions, page: 1, per_page: 2)

      expect(first.records.size).to eq(2)
      expect(first.total_pages).to eq(3)
      expect(first.next_page).to eq(2)
      expect(first.prev_page).to be_nil
      expect(first).to be_multiple_pages
    end

    it "returns the remainder on the last page" do
      last = described_class.new(scope: user.credit_transactions, page: 3, per_page: 2)

      expect(last.records.size).to eq(1)
      expect(last.next_page).to be_nil
      expect(last.prev_page).to eq(2)
    end

    it "does not overlap between pages" do
      scope = user.credit_transactions.order(:id)
      ids = [ 1, 2, 3 ].flat_map { |n| described_class.new(scope: scope, page: n, per_page: 2).records.map(&:id) }

      expect(ids).to eq(ids.uniq)
      expect(ids.size).to eq(5)
    end
  end

  describe "with an out-of-range page" do
    before { create_transactions(3) }

    it "clamps above the last page rather than returning nothing" do
      page = described_class.new(scope: user.credit_transactions, page: 99, per_page: 2)

      expect(page.current_page).to eq(2)
      expect(page.records).not_to be_empty
    end

    it "clamps zero and negative pages to the first one" do
      expect(described_class.new(scope: user.credit_transactions, page: 0).current_page).to eq(1)
      expect(described_class.new(scope: user.credit_transactions, page: -5).current_page).to eq(1)
    end

    it "falls back to the default per_page when given garbage" do
      page = described_class.new(scope: user.credit_transactions, page: 1, per_page: 0)

      expect(page.total_pages).to eq(1)
    end
  end

  describe "with an empty scope" do
    subject(:page) { described_class.new(scope: user.credit_transactions, page: 1) }

    it "still reports one page" do
      expect(page.records).to be_empty
      expect(page.total_count).to eq(0)
      expect(page.total_pages).to eq(1)
      expect(page).to be_empty
      expect(page).not_to be_any
    end
  end

  # L'ancienne vue appelait `@transactions.count` en plus du chargement,
  # soit un COUNT supplémentaire à chaque affichage.
  it "counts the scope only once even when total_count is read repeatedly" do
    scope = user.credit_transactions
    allow(scope).to receive(:count).once.and_return(2)

    page = described_class.new(scope: scope, page: 1)
    3.times { page.total_count }
    page.total_pages

    expect(scope).to have_received(:count).once
  end
end
