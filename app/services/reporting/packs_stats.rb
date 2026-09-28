# frozen_string_literal: true

module Reporting
  class PacksStats
    def initialize(time_zone: "Europe/Paris")
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # Statistiques par mois pour l'année en cours
    def monthly_stats_for_current_year
      last_months_stats(@current_time.month).reverse # Plus récent en premier
    end

    # Statistiques des `count` derniers mois, mois en cours inclus, du plus ancien au plus récent
    def last_months_stats(count)
      (count - 1).downto(0).map do |offset|
        month_start = @current_time.beginning_of_month.months_ago(offset)
        monthly_breakdown(month_start..month_start.end_of_month, month_start)
      end
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
      CreditPurchase
        .where(status: :paid, paid_at: period_range)
        .grouped_by_pack_type
        .pluck(CreditPurchase::PACK_TYPE_SQL, Arel.sql("COUNT(*)"), Arel.sql("SUM(credit_purchases.amount_cents)"))
        .to_h { |type, count, cents| [ type, { count: count, amount: cents / 100.0 } ] }
    end
  end
end
