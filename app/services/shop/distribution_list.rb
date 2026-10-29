# frozen_string_literal: true

module Shop
  # Liste de distribution d'une campagne : une ligne par article commandé et
  # payé, rangée par groupe d'entraînement puis par membre, pour remettre
  # l'équipement à chaque groupe.
  class DistributionList
    HEADERS = [ "Groupe d'entraînement", "Membre", "Commande", "Article", "Coloris", "Coupe", "Taille", "Quantité" ].freeze

    def initialize(campaign)
      @campaign = campaign
    end

    def rows
      orders = Order.paid_status.where(campaign: @campaign).includes(:user).to_a
      groups = TrainingGroups.new(orders.map(&:user_id))
      lines = OrderLine.where(order_id: orders.map(&:id)).order(:id).group_by(&:order_id)
      rows = orders.flat_map { |order| lines.fetch(order.id, []).map { |line| row(order, line, groups.of(order.user_id)) } }
      [ HEADERS, *rows.sort_by { |row| row.first(3) } ]
    end

    private

    def row(order, line, group)
      [ group, order.user.full_name, order.number, line.product_name, line.color_name, line.cut_label, line.size, line.quantity ]
    end
  end
end
