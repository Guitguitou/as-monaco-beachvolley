# frozen_string_literal: true

module Mcp
  module Tools
    # Commandes de la boutique équipements d'une campagne, comme l'onglet
    # Commandes de l'admin, avec le détail de chaque ligne.
    class ListShopOrders < Base
      MAX_RESULTS = 300
      STATUSES = %w[paid unfinished].freeze

      tool_name "list_shop_orders"
      description "Liste les commandes d'équipements d'une campagne (boutique du club) : numéro, joueur et son groupe " \
                  "d'entraînement, statut (paid = payée, unfinished = panier ou paiement non abouti), montant, remise " \
                  "faite ou non, et chaque ligne (marque, article, coupe, coloris, taille, quantité, prix unitaire). " \
                  "Par défaut : la campagne la plus récente, commandes payées et non finalisées. " \
                  "Une correction de taille après paiement met à jour la date de modification de la commande. " \
                  "#{PAGINATION_NOTE}"
      input_schema(
        properties: {
          campaign_id: { type: "integer", description: "Campagne (cf. shop_summary). Défaut : la plus récente." },
          status: { type: "string", enum: STATUSES },
          player_id: { type: "integer", description: "Ne garder que les commandes de ce joueur (cf. list_players)." },
          **PAGINATION_PROPERTIES
        }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context, campaign_id: nil, status: nil, player_id: nil, cursor: nil, updated_since: nil)
          campaign = Admin::ShopCampaignChoice.new(campaign_id).campaign || raise(ActiveRecord::RecordNotFound)
          orders = scoped(campaign, status, player_id)
          page = paginate(orders.includes(:user), cursor, updated_since)
          {
            campaign: { id: campaign.id, name: campaign.name },
            totals: { paid_eur: paid_eur(orders), count_by_status: count_by_status(orders) },
            next_cursor: page[:next_cursor],
            orders: OrderSerializer.new(page[:records]).call
          }
        end

        private

        # Commandes qui ont au moins une ligne : un panier vide n'est pas une commande.
        def scoped(campaign, status, player_id)
          orders = Shop::Order.where(campaign: campaign).where(id: Shop::OrderLine.select(:order_id))
          orders = orders.where(user_id: player_id) if player_id.present?
          return orders if status.blank?
          raise ArgumentError, "Statut inconnu : #{status} (#{STATUSES.join(', ')})" unless STATUSES.include?(status)

          status == "paid" ? orders.paid_status : orders.where.not(status: :paid)
        end

        def paid_eur(orders) = Shop::OrderLine.where(order_id: orders.paid_status.select(:id)).sum("quantity * unit_price_cents") / 100.0

        def count_by_status(orders)
          paid = orders.paid_status.count
          { "paid" => paid, "unfinished" => orders.count - paid }
        end
      end

      # Sérialise une page de commandes avec leurs lignes et le groupe
      # d'entraînement de chaque joueur, en trois requêtes.
      class OrderSerializer
        def initialize(orders)
          @orders = orders
        end

        def call
          lines = Shop::OrderLine.where(order_id: @orders.map(&:id)).includes(:product).order(:id).group_by(&:order_id)
          groups = Shop::TrainingGroups.new(@orders.map(&:user_id))
          @orders.map { |order| order_hash(order, lines.fetch(order.id, []), groups.of(order.user_id)) }
        end

        private

        def order_hash(order, lines, group)
          {
            id: order.id, number: order.number, status: order.paid_status? ? "paid" : "unfinished",
            created_at: paris(order.created_at), updated_at: paris(order.updated_at), paid_at: paris(order.paid_at),
            player_id: order.user_id, player: order.user.full_name, training_group: group,
            amount_eur: lines.sum(&:total_cents) / 100.0,
            handed_over: order.handed_over?, handed_over_at: paris(order.handed_over_at),
            lines: lines.map { |line| line_hash(line) }
          }
        end

        def line_hash(line)
          {
            brand: line.product.brand, product: line.product_name, cut: line.cut_label, color: line.color_name,
            size: line.size, quantity: line.quantity, unit_price_eur: line.unit_price_cents / 100.0
          }
        end

        def paris(time) = time&.in_time_zone(ClubRules.current.time_zone)&.iso8601
      end
    end
  end
end
