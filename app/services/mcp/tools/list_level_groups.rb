# frozen_string_literal: true

module Mcp
  module Tools
    # Joueurs actifs par niveau, comme la vue Groupes de l'admin.
    class ListLevelGroups < Base
      tool_name "list_level_groups"
      description "Niveaux du club et joueurs actifs de chacun (comptes activés et non désactivés). " \
                  "Signale les joueurs présents dans plusieurs groupes. Donne aussi les level_id utilisables ailleurs."
      input_schema(properties: {})
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context)
          level_groups = Users::LevelGroups.new
          {
            groups: level_groups.groups.map do |group|
              {
                level_id: group.level.id,
                level: group.level.display_name,
                members_count: group.members.size,
                members: group.members.map do |user|
                  { id: user.id, name: user.full_name, multi_group: level_groups.multi_group?(user) }
                end
              }
            end
          }
        end
      end
    end
  end
end
