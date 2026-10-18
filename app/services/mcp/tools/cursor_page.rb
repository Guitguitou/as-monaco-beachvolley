# frozen_string_literal: true

module Mcp
  module Tools
    # Une page d'une relation triée de façon stable par `updated_at, id`.
    #
    # Le curseur est opaque pour le client : il encode le couple (updated_at, id)
    # du dernier enregistrement renvoyé ; la page suivante reprend strictement
    # après. `updated_since` (ISO8601, inclus) ne garde que les enregistrements
    # modifiés depuis cet instant.
    class CursorPage
      SEPARATOR = "|"

      def initialize(relation, per_page:, cursor: nil, updated_since: nil)
        @relation = relation
        @per_page = per_page
        @cursor = cursor
        @updated_since = updated_since
      end

      def call
        rows = scope.limit(@per_page + 1).to_a
        records = rows.first(@per_page)
        { records:, next_cursor: rows.size > @per_page ? encode(records.last) : nil }
      end

      private

      def scope
        table = @relation.arel_table
        scope = @relation.reorder(table[:updated_at].asc, table[:id].asc)
        scope = scope.where(table[:updated_at].gteq(parse_time(@updated_since))) if @updated_since.present?
        return scope if @cursor.blank?

        updated_at, id = decode(@cursor)
        scope.where(table[:updated_at].gt(updated_at)
                    .or(table[:updated_at].eq(updated_at).and(table[:id].gt(id))))
      end

      def encode(record)
        Base64.urlsafe_encode64([ record.updated_at.utc.iso8601(6), record.id ].join(SEPARATOR), padding: false)
      end

      def decode(cursor)
        updated_at, id = Base64.urlsafe_decode64(cursor).split(SEPARATOR, 2)
        [ Time.iso8601(updated_at), Integer(id) ]
      rescue ArgumentError, TypeError
        raise ArgumentError, "Curseur invalide : reprends le next_cursor renvoyé par la page précédente."
      end

      def parse_time(value)
        Time.iso8601(value)
      rescue ArgumentError
        raise ArgumentError, "Date invalide : #{value} (format attendu ISO8601, ex. 2026-10-18T06:00:00+02:00)"
      end
    end
  end
end
