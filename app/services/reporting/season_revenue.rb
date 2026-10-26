# frozen_string_literal: true

module Reporting
  # Ventes en euros d'une saison : encaissé par type de pack et par mois, et
  # totaux comparés à la saison précédente à date égale.
  class SeasonRevenue
    PACK_TYPE_LABELS = Admin::Tables::Purchases::PACK_TYPE_LABELS

    def initialize(months)
      @months = months
    end

    def comparisons
      compare = SeasonComparisons.new(self, self.class.new(@months.previous))
      [
        compare.compare(:revenue, "Encaissé", "euro", unit: "€", &:total_eur),
        compare.compare(:purchases, "Achats payés", "shopping-bag") { |report| report.paid.count },
        compare.compare(:buyers, "Acheteurs", "users") { |report| report.paid.distinct.count(:user_id) },
        compare.compare(:basket, "Panier moyen", "receipt", unit: "€", &:average_eur)
      ]
    end

    # Séries Chartkick de l'encaissé (€), une par type de pack vendu sur la saison.
    def revenue_by_pack_type
      cents = @months.group(paid.left_joins(:pack), "credit_purchases.paid_at", by: CreditPurchase::PACK_TYPE_SQL) do |grouped|
        grouped.sum(:amount_cents)
      end
      cents.keys.map(&:first).uniq.sort_by { |type| CreditPurchase::REPORTING_PACK_TYPES.index(type) || 99 }.map do |type|
        { name: label(type), data: @months.series_for(cents, type) { |amount| amount / 100 } }
      end
    end

    # Encaissé et nombre de ventes par type de pack, du plus vendu au moins vendu.
    def by_pack_type
      paid.left_joins(:pack).group(CreditPurchase::PACK_TYPE_SQL)
          .pluck(CreditPurchase::PACK_TYPE_SQL, Arel.sql("COUNT(*)"), Arel.sql("SUM(credit_purchases.amount_cents)"))
          .map { |type, count, amount| { label: label(type), count: count, eur: amount / 100 } }
          .sort_by { |row| -row[:eur] }
    end

    def paid = CreditPurchase.paid_status.where(paid_at: @months.range)

    def total_eur = paid.sum(:amount_cents) / 100

    def average_eur = paid.none? ? 0 : (paid.average(:amount_cents) / 100).round

    private

    def label(type) = PACK_TYPE_LABELS.fetch(type, type.to_s.humanize)
  end
end
