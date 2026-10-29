# frozen_string_literal: true

module Shop
  # Liste de distribution d'une campagne : une ligne par article commandé et
  # payé, avec le membre et son équipe, pour remettre l'équipement au club.
  class DistributionList
    HEADERS = [ "Commande", "Membre", "Équipe", "Article", "Coloris", "Coupe", "Taille", "Quantité" ].freeze

    def initialize(campaign)
      @campaign = campaign
    end

    def rows
      orders = Order.paid_status.where(campaign: @campaign).includes(:user).order(:number).to_a
      lines = OrderLine.where(order_id: orders.map(&:id)).order(:id).group_by(&:order_id)
      [ HEADERS, *orders.flat_map { |order| lines.fetch(order.id, []).map { |line| row(order, line) } } ]
    end

    private

    def row(order, line)
      [ order.number, order.user.full_name, order.team.to_s, line.product_name, line.color_name, line.cut_label, line.size, line.quantity ]
    end
  end
end
