# frozen_string_literal: true

module Admin
  class FinancesTabComponent < ApplicationComponent
    PERIODS = { week: "Semaine", month: "Mois", year: "Année" }.freeze
    REVENUE_STYLES = {
      week: { icon: "calendar", color: "blue" },
      month: { icon: "calendar-days", color: "green" },
      year: { icon: "calendar-check", color: "purple" }
    }.freeze

    def initialize(revenues:, coach_salaries:, breakdowns:)
      @revenues = revenues
      @coach_salaries = coach_salaries
      @breakdowns = breakdowns
    end

    private

    attr_reader :revenues, :coach_salaries, :breakdowns

    def revenue_cards
      cards("CA") { |period| { value: revenues[period], **REVENUE_STYLES[period] } }
    end

    def salary_cards
      cards("Salaires") { |period| { value: coach_salaries[period], icon: "users", color: "orange" } }
    end

    def profit_cards
      cards("Bénéfice") do |period|
        profit = revenues[period] - coach_salaries[period]
        { value: profit, icon: "trending-up", color: profit >= 0 ? "green" : "red" }
      end
    end

    def cards(label)
      PERIODS.map { |period, name| { title: "#{label} #{name}", **yield(period) } }
    end

    def format_currency(amount)
      number_with_precision(amount, precision: 2)
    end
  end
end
