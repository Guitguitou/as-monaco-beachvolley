# frozen_string_literal: true

module Mcp
  module Tools
    # Joueurs du club avec leur niveau, licence et solde, sans coordonnées.
    class ListPlayers < Base
      MAX_RESULTS = 300

      tool_name "list_players"
      description "Liste les membres du club : niveaux, type de licence, solde de crédits, rôles. " \
                  "Filtrable par nom, niveau ou solde. Par défaut seuls les comptes activés et non désactivés. " \
                  "#{PAGINATION_NOTE}"
      input_schema(
        properties: {
          name: { type: "string", description: "Recherche sur le prénom ou le nom." },
          level_id: { type: "integer", description: "Niveau (cf. list_level_groups)." },
          balance_below: { type: "integer", description: "Solde de crédits strictement inférieur à cette valeur." },
          include_inactive: { type: "boolean", description: "Inclure les comptes non activés ou désactivés." },
          **PAGINATION_PROPERTIES
        }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context, name: nil, level_id: nil, balance_below: nil, include_inactive: false, cursor: nil, updated_since: nil)
          page = paginate(scope(name, level_id, balance_below, include_inactive), cursor, updated_since)
          { next_cursor: page[:next_cursor], players: page[:records].map { |user| serialize(user) } }
        end

        private

        def scope(name, level_id, balance_below, include_inactive)
          users = User.includes(:balance, :levels)
          users = users.activated.enabled unless include_inactive
          if name.present?
            pattern = "%#{User.sanitize_sql_like(name)}%"
            users = users.where("first_name ILIKE :p OR last_name ILIKE :p", p: pattern)
          end
          users = users.where(id: UserLevel.where(level_id: level_id).select(:user_id)) if level_id.present?
          users = users.where(id: Balance.where(amount: ...balance_below).select(:user_id)) unless balance_below.nil?
          users
        end

        def serialize(user)
          {
            id: user.id,
            name: user.full_name,
            levels: user.levels.map(&:display_name),
            license_type: user.license_type,
            balance_credits: user.balance&.amount.to_i,
            roles: user.role_labels,
            activated: user.activated_at.present?,
            licence_payee: user.activated?,
            dossier_complet: user.dossier_complet?,
            disabled: user.disabled?
          }
        end
      end
    end
  end
end
