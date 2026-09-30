# frozen_string_literal: true

module Admin
  # Tableau des sessions faites par joueur sur une période : nombre et montant
  # payé, au total et par type de session, avec la navigation entre périodes.
  #
  #   render Admin::PlayerSpendingComponent.new(
  #     spending: Reporting::PlayerSessionSpending.new(period.range),
  #     period: period
  #   )
  class PlayerSpendingComponent < ApplicationComponent
    PERIODS = { "month" => "Mois", "year" => "Année" }.freeze

    def initialize(spending:, period:)
      @spending = spending
      @period = period
    end

    private

    attr_reader :spending, :period

    delegate :rows, :session_types, :totals, to: :spending

    def grand_total = totals.values.reduce(Reporting::PlayerSessionSpending::Stat.empty, :+)

    def stat(row, type) = row.by_type[type]

    def type_label(type) = Sessions::SessionType.for(type).label

    def period_path(name: period.name, anchor: nil) = helpers.admin_finances_path(period: name, period_anchor: anchor, anchor: "players")

    def period_link_classes(name)
      base = "px-3 py-1.5 text-sm rounded-none"
      name == period.name ? "#{base} bg-asmbv-red text-white" : "#{base} bg-gray-100 text-gray-700 hover:bg-gray-200"
    end

    def sessions_label(count) = "#{count} #{'session'.pluralize(count)}"

    def format_currency(amount) = helpers.number_to_currency(amount, unit: "€", format: "%n %u")
  end
end
