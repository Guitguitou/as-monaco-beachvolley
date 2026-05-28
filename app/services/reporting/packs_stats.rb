# frozen_string_literal: true

module Reporting
  class PacksStats
    def initialize(time_zone: "Europe/Paris")
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # Statistiques par mois pour l'année en cours
    def monthly_stats_for_current_year
      year_start = @current_time.beginning_of_year
      year_end = @current_time.end_of_year

      stats = []
      current_month = year_start

      while current_month <= year_end && current_month <= @current_time.end_of_month
        month_range = current_month.beginning_of_month..current_month.end_of_month
        stats << monthly_breakdown(month_range, current_month)
        current_month = current_month.next_month
      end

      stats.reverse # Plus récent en premier
    end

    # Statistiques annuelles (toutes les années avec des achats)
    def yearly_stats
      first_purchase = CreditPurchase.where(status: :paid).order(:paid_at).first
      return [] unless first_purchase

      first_year = first_purchase.paid_at.year
      current_year = @current_time.year

      stats = []
      (first_year..current_year).each do |year|
        year_start = Time.zone.local(year, 1, 1).in_time_zone(@time_zone)
        year_end = year_start.end_of_year
        year_range = year_start..year_end

        stats << yearly_breakdown(year_range, year)
      end

      stats.reverse # Plus récent en premier
    end

    # Détail par pack pour une période donnée
    def pack_details_for_period(period_range)
      purchases = CreditPurchase
        .where(status: :paid, paid_at: period_range)
        .joins(:pack)
        .group("packs.id", "packs.name", "packs.pack_type")
        .select(
          "packs.id as pack_id",
          "packs.name as pack_name",
          "packs.pack_type as pack_type",
          "COUNT(*) as purchase_count",
          "SUM(credit_purchases.amount_cents) as total_cents"
        )

      purchases.map do |p|
        {
          pack_id: p.pack_id,
          pack_name: p.pack_name,
          pack_type: p.pack_type,
          count: p.purchase_count,
          total: p.total_cents / 100.0
        }
      end
    end

    private

    def monthly_breakdown(month_range, month_date)
      by_type = pack_breakdown_by_type(month_range)
      total = by_type.values.sum { |v| v[:amount] }

      {
        period: I18n.l(month_date, format: :month_and_year),
        period_short: month_date.strftime("%m/%Y"),
        month: month_date.month,
        year: month_date.year,
        by_type: by_type,
        total: total,
        range: month_range
      }
    end

    def yearly_breakdown(year_range, year)
      by_type = pack_breakdown_by_type(year_range)
      total = by_type.values.sum { |v| v[:amount] }

      {
        period: year.to_s,
        year: year,
        by_type: by_type,
        total: total,
        range: year_range
      }
    end

    def pack_breakdown_by_type(period_range)
      purchases = CreditPurchase
        .where(status: :paid, paid_at: period_range)
        .joins(:pack)
        .group("packs.pack_type")
        .select(
          "packs.pack_type",
          "COUNT(*) as count",
          "SUM(credit_purchases.amount_cents) as total_cents"
        )

      result = {}
      purchases.each do |p|
        result[p.pack_type] = {
          count: p.count,
          amount: p.total_cents / 100.0
        }
      end
      result
    end
  end
end
