# frozen_string_literal: true

module Admin
  class AlertsTabComponent < ViewComponent::Base
    def initialize(alerts:, alert_counts:)
      @alerts = alerts
      @alert_counts = alert_counts
    end

    private

    attr_reader :alerts, :alert_counts

    def alert_cards
      [
        {
          title: 'Désinscriptions hors délai',
          count: alert_counts[:late_cancellations],
          icon: 'user-x',
          color: 'red',
          data: alerts[:late_cancellations]
        },
        {
          title: 'Alertes de capacité',
          count: alert_counts[:capacity_alerts],
          icon: 'users',
          color: 'yellow',
          data: alerts[:capacity_alerts]
        },
        {
          title: 'Faible participation',
          count: alert_counts[:low_attendance],
          icon: 'alert-triangle',
          color: 'orange',
          data: alerts[:low_attendance]
        },
        {
          title: 'Sessions à venir',
          count: alert_counts[:upcoming_sessions],
          icon: 'calendar',
          color: 'blue',
          data: alerts[:upcoming_sessions]
        }
      ]
    end

    def card_color_classes(color)
      case color
      when 'red'
        'bg-red-50 text-red-600'
      when 'yellow'
        'bg-yellow-50 text-yellow-600'
      when 'orange'
        'bg-orange-50 text-orange-600'
      when 'blue'
        'bg-blue-50 text-blue-600'
      else
        'bg-gray-50 text-gray-600'
      end
    end

    def capacity_alert_type(session)
      return 'unknown' unless session.max_players.present?
      
      ratio = session.registrations.confirmed.count.to_f / session.max_players
      
      case ratio
      when 0...0.4
        'low'
      when 0.9..1.0
        'high'
      else
        'unknown'
      end
    end

    def capacity_alert_text(type)
      case type
      when 'low'
        'Sous-capacité'
      when 'high'
        'Presque plein'
      else
        'Inconnu'
      end
    end

    def capacity_alert_classes(type)
      case type
      when 'low'
        'bg-red-100 text-red-800'
      when 'high'
        'bg-yellow-100 text-yellow-800'
      else
        'bg-gray-100 text-gray-800'
      end
    end
  end
end
