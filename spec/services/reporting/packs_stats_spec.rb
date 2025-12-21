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

  describe '#monthly_stats_for_current_year' do
    let!(:user) { create(:user) }
    let!(:pack_credits) { create(:pack, pack_type: :credits, name: 'Pack 10 crédits', amount_cents: 1000, credits: 10) }
    let!(:pack_licence) { create(:pack, pack_type: :licence, name: 'Licence annuelle', amount_cents: 5000) }

    context 'with purchases in different months' do
      before do
        # Janvier 2024
        create(:credit_purchase,
               user: user,
               pack: pack_credits,
               status: :paid,
               paid_at: Time.zone.parse('2024-01-10 10:00:00'),
               amount_cents: 1000,
               credits: 10)

        create(:credit_purchase,
               user: user,
               pack: pack_credits,
               status: :paid,
               paid_at: Time.zone.parse('2024-01-20 10:00:00'),
               amount_cents: 1000,
               credits: 10)

        # Février 2024
        create(:credit_purchase,
               user: user,
               pack: pack_licence,
               status: :paid,
               paid_at: Time.zone.parse('2024-02-05 10:00:00'),
               amount_cents: 5000,
               credits: 0)

        # Mars 2024 (mois en cours)
        create(:credit_purchase,
               user: user,
               pack: pack_credits,
               status: :paid,
               paid_at: Time.zone.parse('2024-03-10 10:00:00'),
               amount_cents: 1000,
               credits: 10)
      end

      it 'returns stats for each month up to current month' do
        stats = service.monthly_stats_for_current_year

        # Should have stats for Jan, Feb, Mar (3 months)
        expect(stats.size).to eq(3)

        # Verify period names (ordre inversé : plus récent en premier)
        expect(stats[0][:month]).to eq(3) # Mars (plus récent)
        expect(stats[1][:month]).to eq(2) # Février
        expect(stats[2][:month]).to eq(1) # Janvier
      end

      it 'calculates correct totals per month' do
        stats = service.monthly_stats_for_current_year

        january_stat = stats.find { |s| s[:month] == 1 }
        february_stat = stats.find { |s| s[:month] == 2 }
        march_stat = stats.find { |s| s[:month] == 3 }

        expect(january_stat[:total]).to eq(20.0) # 2 x 10€
        expect(february_stat[:total]).to eq(50.0) # 1 x 50€
        expect(march_stat[:total]).to eq(10.0) # 1 x 10€
      end

      it 'groups purchases by pack type correctly' do
        stats = service.monthly_stats_for_current_year

        january_stat = stats.find { |s| s[:month] == 1 }
        february_stat = stats.find { |s| s[:month] == 2 }

        # Janvier: 2 packs de crédits
        expect(january_stat[:by_type]['credits'][:count]).to eq(2)
        expect(january_stat[:by_type]['credits'][:amount]).to eq(20.0)

        # Février: 1 pack licence
        expect(february_stat[:by_type]['licence'][:count]).to eq(1)
        expect(february_stat[:by_type]['licence'][:amount]).to eq(50.0)
      end
    end

    context 'with no purchases' do
      it 'returns empty array' do
        stats = service.monthly_stats_for_current_year
        expect(stats).to be_an(Array)
        expect(stats.size).to eq(3) # Jan, Feb, Mar with zeros
        expect(stats[0][:total]).to eq(0.0)
      end
    end

    context 'with pending purchases' do
      before do
        create(:credit_purchase,
               user: user,
               pack: pack_credits,
               status: :pending, # Not paid
               amount_cents: 1000,
               credits: 10)
      end

      it 'does not include pending purchases' do
        stats = service.monthly_stats_for_current_year
        expect(stats.first[:total]).to eq(0.0)
      end
    end
  end

  describe '#yearly_stats' do
    let!(:user) { create(:user) }
    let!(:pack_credits) { create(:pack, pack_type: :credits, name: 'Pack 10 crédits', amount_cents: 1000, credits: 10) }

    context 'with purchases in different years' do
      before do
        # 2023
        create(:credit_purchase,
               user: user,
               pack: pack_credits,
               status: :paid,
               paid_at: Time.zone.parse('2023-06-15 10:00:00'),
               amount_cents: 1000,
               credits: 10)

        create(:credit_purchase,
               user: user,
               pack: pack_credits,
               status: :paid,
               paid_at: Time.zone.parse('2023-12-20 10:00:00'),
               amount_cents: 1000,
               credits: 10)

        # 2024
        create(:credit_purchase,
               user: user,
               pack: pack_credits,
               status: :paid,
               paid_at: Time.zone.parse('2024-01-10 10:00:00'),
               amount_cents: 1000,
               credits: 10)
      end

      it 'returns stats for all years with purchases' do
        stats = service.yearly_stats

        expect(stats.size).to eq(2)
        # Reverse order: most recent first
        expect(stats[0][:year]).to eq(2024)
        expect(stats[1][:year]).to eq(2023)
      end

      it 'calculates correct totals per year' do
        stats = service.yearly_stats

        year_2024_stat = stats.find { |s| s[:year] == 2024 }
        year_2023_stat = stats.find { |s| s[:year] == 2023 }

        expect(year_2024_stat[:total]).to eq(10.0) # 1 x 10€
        expect(year_2023_stat[:total]).to eq(20.0) # 2 x 10€
      end

      it 'groups purchases by pack type correctly' do
        stats = service.yearly_stats

        year_2023_stat = stats.find { |s| s[:year] == 2023 }

        expect(year_2023_stat[:by_type]['credits'][:count]).to eq(2)
        expect(year_2023_stat[:by_type]['credits'][:amount]).to eq(20.0)
      end
    end

    context 'with no purchases' do
      it 'returns empty array' do
        stats = service.yearly_stats
        expect(stats).to eq([])
      end
    end
  end

  describe '#pack_details_for_period' do
    let!(:user) { create(:user) }
    let!(:pack1) { create(:pack, pack_type: :credits, name: 'Pack Petit', amount_cents: 1000, credits: 10) }
    let!(:pack2) { create(:pack, pack_type: :credits, name: 'Pack Grand', amount_cents: 5000, credits: 60) }

    let(:period_range) { Time.zone.parse('2024-03-01')..Time.zone.parse('2024-03-31') }

    context 'with multiple purchases of different packs' do
      before do
        # 2 achats du pack1
        create(:credit_purchase,
               user: user,
               pack: pack1,
               status: :paid,
               paid_at: Time.zone.parse('2024-03-10 10:00:00'),
               amount_cents: 1000,
               credits: 10)

        create(:credit_purchase,
               user: user,
               pack: pack1,
               status: :paid,
               paid_at: Time.zone.parse('2024-03-15 10:00:00'),
               amount_cents: 1000,
               credits: 10)

        # 1 achat du pack2
        create(:credit_purchase,
               user: user,
               pack: pack2,
               status: :paid,
               paid_at: Time.zone.parse('2024-03-20 10:00:00'),
               amount_cents: 5000,
               credits: 60)
      end

      it 'returns details for each pack' do
        details = service.pack_details_for_period(period_range)

        expect(details.size).to eq(2)

        pack1_details = details.find { |d| d[:pack_id] == pack1.id }
        pack2_details = details.find { |d| d[:pack_id] == pack2.id }

        expect(pack1_details[:pack_name]).to eq('Pack Petit')
        expect(pack1_details[:count]).to eq(2)
        expect(pack1_details[:total]).to eq(20.0)

        expect(pack2_details[:pack_name]).to eq('Pack Grand')
        expect(pack2_details[:count]).to eq(1)
        expect(pack2_details[:total]).to eq(50.0)
      end
    end

    context 'with purchases outside the period' do
      before do
        create(:credit_purchase,
               user: user,
               pack: pack1,
               status: :paid,
               paid_at: Time.zone.parse('2024-02-15 10:00:00'), # Février, pas mars
               amount_cents: 1000,
               credits: 10)
      end

      it 'does not include purchases outside period' do
        details = service.pack_details_for_period(period_range)
        expect(details).to be_empty
      end
    end
  end
end
