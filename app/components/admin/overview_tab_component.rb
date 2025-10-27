# frozen_string_literal: true

module Admin
  class OverviewTabComponent < ViewComponent::Base
    def initialize(kpis:, upcoming_sessions:, alerts:)
      @kpis = kpis
      @upcoming_sessions = upcoming_sessions
      @alerts = alerts
    end

    private

    attr_reader :kpis, :upcoming_sessions, :alerts

    def kpi_cards
      [
        {
          title: 'Entraînements (semaine)',
          value: kpis[:trainings_count],
          icon: 'dumbbell',
          color: 'blue'
        },
        {
          title: 'Jeux libres (semaine)',
          value: kpis[:free_plays_count],
          icon: 'gamepad-2',
          color: 'green'
        },
        {
          title: 'Coachings privés (semaine)',
          value: kpis[:private_coachings_count],
          icon: 'user-check',
          color: 'purple'
        },
        {
          title: 'Désinscriptions hors délai',
          value: kpis[:late_cancellations_count],
          icon: 'user-x',
          color: 'red'
        },
        {
          title: 'CA semaine (€)',
          value: number_with_precision(kpis[:revenue], precision: 2),
          icon: 'euro',
          color: 'green'
        },
        {
          title: 'Salaires coachs (€)',
          value: number_with_precision(kpis[:coach_salaries], precision: 2),
          icon: 'users',
          color: 'orange'
        },
        {
          title: 'Différence (€)',
          value: number_with_precision(kpis[:net_profit], precision: 2),
          icon: 'trending-up',
          color: kpis[:net_profit] >= 0 ? 'green' : 'red'
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
  end
end
