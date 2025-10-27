# frozen_string_literal: true

module Admin
  class FinancesTabComponent < ViewComponent::Base
    def initialize(revenues:, coach_salaries:, breakdowns:)
      @revenues = revenues
      @coach_salaries = coach_salaries
      @breakdowns = breakdowns
    end

    private

    attr_reader :revenues, :coach_salaries, :breakdowns

    def revenue_cards
      [
        {
          title: 'CA Semaine',
          value: revenues[:week],
          icon: 'calendar',
          color: 'blue'
        },
        {
          title: 'CA Mois',
          value: revenues[:month],
          icon: 'calendar-days',
          color: 'green'
        },
        {
          title: 'CA Année',
          value: revenues[:year],
          icon: 'calendar-check',
          color: 'purple'
        }
      ]
    end

    def salary_cards
      [
        {
          title: 'Salaires Semaine',
          value: coach_salaries[:week],
          icon: 'users',
          color: 'orange'
        },
        {
          title: 'Salaires Mois',
          value: coach_salaries[:month],
          icon: 'users',
          color: 'orange'
        },
        {
          title: 'Salaires Année',
          value: coach_salaries[:year],
          icon: 'users',
          color: 'orange'
        }
      ]
    end

    def profit_cards
      [
        {
          title: 'Bénéfice Semaine',
          value: revenues[:week] - coach_salaries[:week],
          icon: 'trending-up',
          color: revenues[:week] - coach_salaries[:week] >= 0 ? 'green' : 'red'
        },
        {
          title: 'Bénéfice Mois',
          value: revenues[:month] - coach_salaries[:month],
          icon: 'trending-up',
          color: revenues[:month] - coach_salaries[:month] >= 0 ? 'green' : 'red'
        },
        {
          title: 'Bénéfice Année',
          value: revenues[:year] - coach_salaries[:year],
          icon: 'trending-up',
          color: revenues[:year] - coach_salaries[:year] >= 0 ? 'green' : 'red'
        }
      ]
    end

    def card_color_classes(color)
      case color
      when 'blue'
        'bg-blue-50 text-blue-600'
      when 'green'
        'bg-green-50 text-green-600'
      when 'purple'
        'bg-purple-50 text-purple-600'
      when 'red'
        'bg-red-50 text-red-600'
      when 'orange'
        'bg-orange-50 text-orange-600'
      else
        'bg-gray-50 text-gray-600'
      end
    end

    def format_currency(amount)
      number_with_precision(amount, precision: 2)
    end
  end
end
