# frozen_string_literal: true

module Mcp
  module Tools
    # Socle des tools MCP : vérifie le droit requis via Ability, puis renvoie le
    # résultat de `execute` en JSON (texte + contenu structuré).
    #
    # Attention : `authorize!(:read, User)` sur une classe passe dès qu'une règle
    # conditionnelle existe (un responsable financier peut lire SON profil).
    # Les données des joueurs sont donc gardées par le sujet symbolique
    # `:admin_users`, accordé aux seuls admins (`can :manage, :all`), comme les
    # pages Joueurs et Groupes de l'admin.
    #
    # Chaque tool déclare `permission` ([action, sujet]) et implémente
    # `execute(context, **arguments)` qui renvoie un Hash.
    class Base < MCP::Tool
      READ_ONLY = { read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false }.freeze

      class << self
        def call(server_context:, **arguments)
          server_context.authorize!(*permission)
          data = execute(server_context, **arguments)
          MCP::Tool::Response.new([ { type: "text", text: data.to_json } ], structured_content: data)
        rescue CanCan::AccessDenied
          error("Accès refusé : ton rôle ne permet pas de consulter ces données.")
        rescue ActiveRecord::RecordNotFound
          error("Introuvable.")
        rescue ArgumentError => e
          error(e.message)
        end

        private

        def error(message)
          MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
        end

        def parse_date(value, default)
          return default if value.blank?

          Date.iso8601(value)
        rescue Date::Error
          raise ArgumentError, "Date invalide : #{value} (format attendu AAAA-MM-JJ)"
        end

        def paris_time(time)
          time&.in_time_zone("Europe/Paris")&.iso8601
        end
      end
    end
  end
end
