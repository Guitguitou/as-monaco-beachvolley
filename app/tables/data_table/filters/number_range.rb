# frozen_string_literal: true

module DataTable
  module Filters
    # Plage numérique (crédits, montant…). `scale` convertit la saisie vers la
    # valeur stockée : 100 pour des euros saisis et des centimes en base.
    class NumberRange < Range
      def initialize(sql = nil, scale: 1, scope: nil)
        super(sql, scope: scope)
        @scale = scale
      end

      private

      def parse(value)
        number = BigDecimal(value.to_s.tr(",", ".").strip, exception: false) if value.present?
        number && (number * @scale)
      end
    end
  end
end
