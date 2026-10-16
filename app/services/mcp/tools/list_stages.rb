# frozen_string_literal: true

module Mcp
  module Tools
    # Stages organisés par le club.
    class ListStages < Base
      tool_name "list_stages"
      description "Liste les stages du club : dates, coachs, prix. Par défaut seuls les stages à venir ou en cours."
      input_schema(
        properties: { include_past: { type: "boolean", description: "Inclure les stages passés." } }
      )
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, Stage ]

        def execute(_context, include_past: false)
          stages = Stage.includes(:main_coach, :assistant_coach).order(:starts_on)
          stages = stages.where(ends_on: Date.current..) unless include_past

          {
            stages: stages.map do |stage|
              {
                id: stage.id,
                title: stage.title,
                starts_on: stage.starts_on.iso8601,
                ends_on: stage.ends_on.iso8601,
                main_coach: stage.main_coach&.full_name,
                assistant_coach: stage.assistant_coach&.full_name,
                price_eur: stage.price
              }
            end
          }
        end
      end
    end
  end
end
