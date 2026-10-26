# frozen_string_literal: true

module Admin
  module Tables
    # Historique des achats en euros (Sherlock's).
    class Purchases < DataTable::Definition
      STATUS_LABELS = CreditPurchases::ExportTable::STATUS_LABELS
      PACK_TYPE_LABELS = CreditPurchases::ExportTable::PACK_TYPE_LABELS.merge(CreditPurchase::OTHER_PACK_TYPE => "Achat direct")

      def columns
        [
          DataTable::Column.new(key: :created_at, label: "Date", sort: "credit_purchases.created_at",
                                filter: DataTable::Filters::DateRange.new("credit_purchases.created_at")),
          DataTable::Column.new(key: :user, label: "Joueur", sort: %w[users.last_name users.first_name]),
          DataTable::Column.new(key: :pack_type, label: "Pack", filter: pack_type_filter),
          DataTable::Column.new(key: :amount, label: "Montant", sort: "credit_purchases.amount_cents",
                                filter: DataTable::Filters::NumberRange.new("credit_purchases.amount_cents", scale: 100)),
          DataTable::Column.new(key: :credits, label: "Crédits", sort: "credit_purchases.credits"),
          DataTable::Column.new(key: :status, label: "Statut", sort: "credit_purchases.status",
                                filter: DataTable::Filters::Select.new("credit_purchases.status", options: STATUS_LABELS.invert.to_a,
                                                                                                    multiple: true)),
          DataTable::Column.new(key: :reference, label: "Référence")
        ]
      end

      def search_columns
        %w[users.first_name users.last_name users.email credit_purchases.sherlock_transaction_reference]
      end

      def quick_filters
        [
          DataTable::QuickFilter.new(key: :this_month, label: "Ce mois-ci",
                                     scope: ->(purchases) { purchases.where(created_at: Time.current.all_month) }),
          DataTable::QuickFilter.new(key: :to_check, label: "Échoués / annulés",
                                     scope: ->(purchases) { purchases.where(status: %w[failed cancelled]) })
        ]
      end

      def default_order = { created_at: :desc }

      private

      def pack_type_filter
        DataTable::Filters::Select.new(
          options: CreditPurchase::REPORTING_PACK_TYPES.map { |type| [ PACK_TYPE_LABELS.fetch(type, type.humanize), type ] },
          scope: ->(purchases, type) { purchases.where(CreditPurchase::PACK_TYPE_SQL.eq(type)) }
        )
      end
    end
  end
end
