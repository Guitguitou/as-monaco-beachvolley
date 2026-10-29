# frozen_string_literal: true

module Admin
  # Commandes d'une campagne dans le back-office : chiffres clés et liste,
  # payées d'abord, puis paniers et paiements non aboutis à relancer.
  class ShopOrdersBoard
    FILTERS = { "paid" => "Payées", "unfinished" => "Non finalisées" }.freeze
    Kpi = Data.define(:label, :value, :hint)

    attr_reader :campaign, :filter

    def initialize(campaign:, filter:)
      @campaign = campaign
      @filter = FILTERS.key?(filter) ? filter : nil
    end

    def orders
      scopes = { "paid" => [ paid ], "unfinished" => [ unfinished ] }.fetch(filter) { [ paid, unfinished ] }
      scopes.flat_map(&:to_a)
    end

    def kpis
      [
        Kpi.new("Commandes payées", paid.count.to_s, "sur #{baskets(paid.count + unfinished.count)}"),
        Kpi.new("Encaissé", euros(paid_lines.sum("quantity * unit_price_cents")), "par carte"),
        Kpi.new("Articles à commander", paid_lines.sum(:quantity).to_s, "toutes marques"),
        Kpi.new("Non finalisées", unfinished.count.to_s, "à relancer avant la clôture")
      ]
    end

    def lines_of(order) = (@lines ||= Shop::OrderLine.where(order_id: orders.map(&:id)).order(:id).group_by(&:order_id)).fetch(order.id, [])

    private

    def paid = Shop::Order.paid_status.where(campaign: campaign).includes(:user).order(paid_at: :desc)

    def unfinished = Shop::Order.unfinished.where(campaign: campaign).includes(:user).order(updated_at: :desc)

    def paid_lines = Shop::OrderLine.where(order_id: paid.select(:id))

    def baskets(count) = count > 1 ? "#{count} paniers validés ou en cours" : "#{count} panier validé ou en cours"

    def euros(cents) = ActiveSupport::NumberHelper.number_to_currency(cents / 100.0, unit: "€", format: "%n %u", separator: ",", delimiter: " ")
  end
end
