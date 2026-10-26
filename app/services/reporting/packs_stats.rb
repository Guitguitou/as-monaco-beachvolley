# frozen_string_literal: true

module Reporting
  class PacksStats
    def initialize(time_zone: ClubRules.current.time_zone)
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # Statistiques des `count` derniers mois, mois en cours inclus, du plus ancien au plus récent
    def last_months_stats(count)
      (count - 1).downto(0).map do |offset|
        month_start = @current_time.beginning_of_month.months_ago(offset)
        monthly_breakdown(month_start..month_start.end_of_month, month_start)
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

    def pack_breakdown_by_type(period_range)
      CreditPurchase
        .where(status: :paid, paid_at: period_range)
        .grouped_by_pack_type
        .pluck(CreditPurchase::PACK_TYPE_SQL, Arel.sql("COUNT(*)"), Arel.sql("SUM(credit_purchases.amount_cents)"))
        .to_h { |type, count, cents| [ type, { count: count, amount: cents / 100.0 } ] }
    end
  end
end
