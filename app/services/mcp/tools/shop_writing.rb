# frozen_string_literal: true

module Mcp
  module Tools
    # Ce que partagent les tools qui gèrent la boutique équipements : le droit
    # requis (admins uniquement, via le sujet symbolique `:admin_shop`, comme
    # l'admin de la boutique) et la forme des enregistrements renvoyés.
    module ShopWriting
      PERMISSION = [ :manage, :admin_shop ].freeze
      ID = { type: "integer", description: "Absent : crée. Présent : modifie seulement les champs fournis." }.freeze

      # L'enregistrement à modifier, ou un nouveau sans id.
      def self.find_or_new(scope, id) = id ? scope.find(id) : scope.new

      def self.campaign(campaign)
        campaign.slice(:id, :name, :status, :welcome_message, :allow_edits)
                .merge(opens_on: campaign.opens_on&.iso8601, closes_on: campaign.closes_on&.iso8601)
      end

      def self.product(product)
        product.slice(:id, :name, :brand, :description, :marking, :position, :active).merge(
          cuts: Shop::Cut.of(product).map { |each| cut(each) },
          colors: Shop::Color.of(product).includes(photo_attachment: :blob).map { |each| color(each) }
        )
      end

      def self.cut(cut)
        cut.slice(:id, :product_id, :label, :sizes, :size_guide_id, :position).merge(price_eur: cut.price_eur)
      end

      def self.color(color)
        color.slice(:id, :product_id, :name, :hex, :position).merge(has_photo: color.photo.attached?)
      end

      def self.size_guide(guide) = guide.slice(:id, :name, :measure_label, :rows)
    end
  end
end
