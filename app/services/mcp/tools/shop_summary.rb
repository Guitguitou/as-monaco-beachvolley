# frozen_string_literal: true

module Mcp
  module Tools
    # Récap d'une campagne de la boutique équipements, tel qu'il part chez les
    # marques, comme l'onglet Récap de l'admin.
    class ShopSummary < Base
      tool_name "shop_summary"
      description "Récap d'une campagne de commande groupée d'équipements : quantités par marque, article, coloris, " \
                  "coupe et taille (commandes payées uniquement, tel qu'envoyé à Joma et Nine), montant encaissé et " \
                  "nombre de commandes par statut. Donne aussi la liste des campagnes et leurs campaign_id."
      input_schema(
        properties: { campaign_id: { type: "integer", description: "Campagne. Défaut : la plus récente." } }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context, campaign_id: nil)
          choice = Admin::ShopCampaignChoice.new(campaign_id)
          campaign = choice.campaign || raise(ActiveRecord::RecordNotFound)
          board = Admin::ShopOrdersBoard.new(campaign: campaign, filter: nil)
          {
            campaign: campaign_hash(campaign),
            campaigns: Shop::Campaign.ordered.map { |each| { id: each.id, name: each.name } },
            totals: totals(campaign, board),
            brands: Shop::CampaignRecap.new(campaign).brands.map { |brand| brand_hash(brand) }
          }
        end

        private

        def campaign_hash(campaign)
          campaign.slice(:id, :name, :status).merge(opens_on: campaign.opens_on.iso8601, closes_on: campaign.closes_on.iso8601,
                                                     accepting_orders: campaign.accepting_orders?)
        end

        def totals(campaign, board)
          paid = Shop::Order.paid_status.where(campaign: campaign)
          {
            paid_eur: Shop::OrderLine.where(order_id: paid.select(:id)).sum("quantity * unit_price_cents") / 100.0,
            articles: Shop::OrderLine.where(order_id: paid.select(:id)).sum(:quantity),
            count_by_status: { "paid" => paid.count, "unfinished" => board.orders.count { |order| !order.paid_status? } },
            handed_over: paid.where.not(handed_over_at: nil).count
          }
        end

        def brand_hash(brand)
          {
            brand: brand.name, quantity: brand.quantity,
            items: brand.rows.map do |row|
              { product: row.product_name, color: row.color_name, cut: row.cut_label, quantity: row.quantity,
                sizes: row.sizes.map { |size, quantity| { size: size, quantity: quantity } } }
            end
          }
        end
      end
    end
  end
end
