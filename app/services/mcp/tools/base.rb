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
      PAGINATION_PROPERTIES = {
        cursor: { type: "string", description: "Curseur opaque : le next_cursor de la page précédente pour obtenir la suivante." },
        updated_since: { type: "string", format: "date-time",
                         description: "Ne garder que ce qui a été créé ou modifié depuis cet instant (ISO8601, inclus)." }
      }.freeze
      PAGINATION_NOTE = "Résultats triés par date de modification puis id, par pages de 300 au plus : " \
                        "tant que next_cursor n'est pas null, rappelle le tool avec ce cursor pour la suite."

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

        # Période [début, fin] sur la date de création ; le mois en cours par
        # défaut, sauf avec updated_since sans bornes : aucune période.
        def period(from, to, updated_since)
          return if updated_since.present? && from.blank? && to.blank?

          start_on = parse_date(from, Date.current.beginning_of_month)
          [ start_on, parse_date(to, start_on.end_of_month) ]
        end

        def parse_date(value, default)
          return default if value.blank?

          Date.iso8601(value)
        rescue Date::Error
          raise ArgumentError, "Date invalide : #{value} (format attendu AAAA-MM-JJ)"
        end

        def paginate(relation, cursor, updated_since)
          CursorPage.new(relation, per_page: self::MAX_RESULTS, cursor:, updated_since:).call
        end

        def paris_time(time)
          time&.in_time_zone(ClubRules.current.time_zone)&.iso8601
        end
      end
    end
  end
end
