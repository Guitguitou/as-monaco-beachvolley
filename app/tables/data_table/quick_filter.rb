# frozen_string_literal: true

module DataTable
  # Filtre rapide affiché en pastille au-dessus du tableau
  # (« Ne peut pas réserver », « Sans encadrant »…).
  class QuickFilter < Data.define(:key, :label, :scope)
    def apply(relation) = scope.call(relation)
  end
end
