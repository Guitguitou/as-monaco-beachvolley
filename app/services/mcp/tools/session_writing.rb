# frozen_string_literal: true

module Mcp
  module Tools
    # Ce que partagent les tools qui créent ou modifient une session : les
    # champs acceptés, leur conversion en attributs et la session renvoyée.
    #
    # Réservé aux admins via le sujet symbolique `:admin_sessions` : un coach
    # peut gérer des sessions dans l'app, mais pas depuis son Claude.
    class SessionWriting
      PERMISSION = [ :manage, :admin_sessions ].freeze
      PROPERTIES = {
        title: { type: "string" },
        description: { type: "string" },
        session_type: { type: "string", enum: Session.session_types.keys },
        start_at: { type: "string", format: "date-time", description: "Début (ISO8601 ; sans fuseau : heure de Paris)." },
        end_at: { type: "string", format: "date-time",
                  description: "Fin. Par défaut 90 minutes après le début pour un entraînement, un jeu libre ou un coaching privé." },
        terrain_id: { type: "integer" },
        user_id: { type: "integer", description: "Encadrant (coach, ou responsable pour le jeu libre)." },
        max_players: { type: "integer" },
        level_ids: { type: "array", items: { type: "integer" }, description: "Niveaux ouverts (cf. list_level_groups)." }
      }.freeze

      def self.attributes(arguments)
        attributes = arguments.slice(*PROPERTIES.keys)
        %i[start_at end_at].each { |key| attributes[key] = parse_time(attributes[key]) if attributes.key?(key) }
        attributes
      end

      def self.parse_time(value)
        return if value.blank?

        ClubRules.current.zone.iso8601(value)
      rescue ArgumentError
        raise ArgumentError, "Date-heure invalide : #{value} (format attendu ISO8601)"
      end

      def self.serialize(session)
        {
          id: session.id,
          title: session.title,
          session_type: session.session_type,
          start_at: session.start_at&.in_time_zone(ClubRules.current.time_zone)&.iso8601,
          end_at: session.end_at&.in_time_zone(ClubRules.current.time_zone)&.iso8601,
          terrain: session.terrain&.name,
          encadrant: session.user&.full_name,
          levels: session.levels.map(&:display_name),
          price_credits: session.price,
          max_players: session.max_players
        }
      end
    end
  end
end
