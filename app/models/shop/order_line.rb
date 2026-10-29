# frozen_string_literal: true

module Shop
  # Ligne d'une commande : l'article tel qu'il était à l'ajout (libellés et
  # prix recopiés), pour que modifier le catalogue ne réécrive rien.
  class OrderLine < ApplicationRecord
    MAX_QUANTITY = 20

    # Une correction de taille date la commande : le connecteur la voit avec updated_since.
    belongs_to :order, touch: true
    belongs_to :product
    belongs_to :cut, optional: true
    belongs_to :color, optional: true

    validates :product_name, :cut_label, :color_name, :size, presence: true
    validates :quantity, numericality: { only_integer: true, in: 1..MAX_QUANTITY }
    validates :unit_price_cents, numericality: { greater_than: 0 }

    scope :of, ->(order) { where(order_id: order.id).order(:id) }

    def total_cents = quantity * unit_price_cents

    def details = [ color_name, cut_label, size ].uniq.join(" · ")
  end
end
