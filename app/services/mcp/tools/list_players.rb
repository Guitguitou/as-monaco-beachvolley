# frozen_string_literal: true

module Mcp
  module Tools
    # Joueurs du club avec leur niveau, licence et solde, sans coordonnées.
    class ListPlayers < Base
      MAX_RESULTS = 300

      tool_name "list_players"
      description "Liste les membres du club : niveaux, type de licence, solde de crédits, rôles. " \
                  "Filtrable par nom, niveau ou solde. Par défaut seuls les comptes activés et non désactivés."
      input_schema(
        properties: {
          name: { type: "string", description: "Recherche sur le prénom ou le nom." },
          level_id: { type: "integer", description: "Niveau (cf. list_level_groups)." },
          balance_below: { type: "integer", description: "Solde de crédits strictement inférieur à cette valeur." },
          include_inactive: { type: "boolean", description: "Inclure les comptes non activés ou désactivés." }
        }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context, name: nil, level_id: nil, balance_below: nil, include_inactive: false)
          users = scope(name, level_id, balance_below, include_inactive).to_a
          { truncated: users.size == MAX_RESULTS, players: users.map { |user| serialize(user) } }
        end

        private

        def scope(name, level_id, balance_below, include_inactive)
          users = User.includes(:balance, :levels).order(:last_name, :first_name).limit(MAX_RESULTS)
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
            disabled: user.disabled?
          }
        end
      end
    end
  end
end
