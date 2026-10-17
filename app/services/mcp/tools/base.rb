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

        # Période demandée en dates, le mois en cours par défaut.
        def month_period(from, to)
          start_on = parse_date(from, Date.current.beginning_of_month)
          start_on..parse_date(to, start_on.end_of_month)
        end

        # Bornes horaires couvrant tous les jours de la période.
        def day_bounds(period)
          period.begin.in_time_zone.beginning_of_day..period.end.in_time_zone.end_of_day
        end

        def period_payload(period)
          { from: period.begin.iso8601, to: period.end.iso8601 }
        end

        # Liste plafonnée à `limit` lignes, et si elle a été tronquée.
        def capped(relation, limit)
          rows = relation.limit(limit).to_a
          [ rows, rows.size == limit ]
        end
      end
    end
  end
end
