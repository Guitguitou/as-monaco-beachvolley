# frozen_string_literal: true

module Admin
  class SessionsTabComponent < ViewComponent::Base
    def initialize(sessions:, filters: {})
      @sessions = sessions
      @filters = filters
    end

    private

    attr_reader :sessions, :filters

    def session_types
      [
        { value: '', label: 'Tous les types' },
        { value: 'entrainement', label: 'Entraînements' },
        { value: 'jeu_libre', label: 'Jeux libres' },
        { value: 'coaching_prive', label: 'Coachings privés' }
      ]
    end

    def coaches
      User.coachs.order(:first_name, :last_name).map do |coach|
        { value: coach.id, label: coach.full_name }
      end
    end

    def terrains
      Session.terrain.values.map do |terrain|
        { value: terrain, label: terrain }
      end
    end

    def capacity_status(session)
      return 'unknown' unless session.max_players.present?
      
      ratio = session.registrations.confirmed.count.to_f / session.max_players
      
      case ratio
      when 0...0.4
        'low'
      when 0.4...0.7
        'medium'
      when 0.7...0.9
        'high'
      else
        'full'
      end
    end

    def capacity_status_classes(status)
      case status
      when 'low'
        'bg-red-100 text-red-800'
      when 'medium'
        'bg-yellow-100 text-yellow-800'
      when 'high'
        'bg-blue-100 text-blue-800'
      when 'full'
        'bg-green-100 text-green-800'
      else
        'bg-gray-100 text-gray-800'
      end
    end

    def capacity_status_text(status)
      case status
      when 'low'
        'Sous-capacité'
      when 'medium'
        'Normal'
      when 'high'
        'Presque plein'
      when 'full'
        'Complet'
      else
        'Inconnu'
      end
    end
  end
end
