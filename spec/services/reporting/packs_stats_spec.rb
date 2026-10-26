# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporting::PacksStats do
  let(:service) { described_class.new(time_zone: 'Europe/Paris') }
  let(:current_time) { Time.zone.parse('2024-03-15 10:00:00') } # Vendredi 15 mars 2024

  before do
    travel_to(current_time)
    Reporting::CacheService.clear_all
  end

  after do
    travel_back
  end

  describe '#last_months_stats' do
    let!(:user) { create(:user) }
    let!(:pack_credits) { create(:pack, pack_type: :credits, name: 'Pack 10 crédits', amount_cents: 1000, credits: 10) }

    before do
      create(:credit_purchase, user: user, pack: pack_credits, status: :paid,
             paid_at: Time.zone.parse('2023-12-10 10:00:00'), amount_cents: 3000, credits: 30)
    end

    it 'returns the requested months in chronological order, across years' do
      stats = service.last_months_stats(4)

      expect(stats.map { |s| [ s[:year], s[:month] ] }).to eq([ [ 2023, 12 ], [ 2024, 1 ], [ 2024, 2 ], [ 2024, 3 ] ])
      expect(stats.first[:total]).to eq(30.0)
      expect(stats.last[:total]).to eq(0.0)
    end

    it 'keeps purchases of deleted packs under "autre"' do
      pack_credits.destroy!

      december = service.last_months_stats(4).first

      expect(december[:by_type]).to eq('autre' => { count: 1, amount: 30.0 })
      expect(december[:total]).to eq(30.0)
    end
  end
end
