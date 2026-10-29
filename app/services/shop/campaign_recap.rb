# frozen_string_literal: true

module Shop
  # Récap d'une campagne pour les marques : les lignes des commandes payées,
  # regroupées par marque puis par article, coloris et coupe, avec la
  # quantité par taille dans l'ordre de la coupe.
  class CampaignRecap
    HEADERS = [ "Marque", "Article", "Coloris", "Coupe", "Taille", "Quantité" ].freeze

    Row = Data.define(:product_name, :color_name, :cut_label, :sizes) do
      def label = [ product_name, color_name, cut_label ].join(" · ")

      def quantity = sizes.sum(&:last)
    end

    Brand = Data.define(:name, :rows) do
      def quantity = rows.sum(&:quantity)
    end

    def initialize(campaign)
      @campaign = campaign
    end

    def brands
      lines.group_by { |line| line.product.brand }.sort.map { |name, brand_lines| Brand.new(name, rows_for(brand_lines)) }
    end

    def flat_rows
      [ HEADERS, *brands.flat_map { |brand| brand.rows.flat_map { |row| row.sizes.map { |size, qty| flat_row(brand, row, size, qty) } } } ]
    end

    private

    def lines
      @lines ||= OrderLine.where(order_id: Order.paid_status.where(campaign: @campaign).select(:id)).includes(:product, :cut).to_a
    end

    def rows_for(brand_lines)
      brand_lines.group_by { |line| [ line.product_name, line.color_name, line.cut_label ] }.sort.map do |key, grouped|
        Row.new(*key, sizes_of(grouped))
      end
    end

    def sizes_of(grouped)
      order = grouped.filter_map(&:cut).first&.sizes || []
      grouped.group_by(&:size).transform_values { |same| same.sum(&:quantity) }
             .sort_by { |size, _| [ order.index(size) || order.size, size ] }
    end

    def flat_row(brand, row, size, quantity) = [ brand.name, row.product_name, row.color_name, row.cut_label, size, quantity ]
  end
end
