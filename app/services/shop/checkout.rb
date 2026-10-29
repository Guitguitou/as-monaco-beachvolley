# frozen_string_literal: true

module Shop
  # Validation du panier : vérifie qu'il peut encore être commandé, le
  # verrouille, puis ouvre l'achat Sherlock's du montant de ses lignes. Le
  # membre ne saisit jamais de montant.
  class Checkout
    Result = Data.define(:purchase, :payment_request, :error)

    def initialize(order:, team: nil)
      @order = order
      @team = team
    end

    def call
      error = refusal
      return Result.new(purchase: nil, payment_request: nil, error: error) if error

      purchase = ActiveRecord::Base.transaction do
        @order.update!(status: :awaiting_payment, team: @team.presence)
        @order.user.credit_purchases.create!(shop_order: @order, amount_cents: @order.total_cents, currency: "EUR", credits: 0, status: :pending)
      end
      Result.new(purchase: purchase, payment_request: Sherlock::CreatePayment.new(purchase).call, error: nil)
    end

    private

    def refusal
      return "Les commandes sont fermées." unless @order.campaign.accepting_orders?
      return "Ton panier est vide." if lines.empty?

      unavailable = lines.find { |line| line.cut.nil? || !line.product.active? }
      "#{unavailable.product_name} n'est plus en vente : retire-le du panier." if unavailable
    end

    def lines = @lines ||= @order.lines.includes(:cut, :product).to_a
  end
end
