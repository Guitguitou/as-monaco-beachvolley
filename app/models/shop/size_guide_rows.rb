# frozen_string_literal: true

module Shop
  # Saisie texte d'un guide des tailles : « taille ; mesure ; repère », une
  # ligne par taille, le repère étant facultatif.
  module SizeGuideRows
    SEPARATOR = ";"
    KEYS = %w[size measure note].freeze

    def self.parse(text)
      text.to_s.lines.map { |line| line.split(SEPARATOR).map(&:strip) }
          .reject { |cells| cells.first.blank? }
          .map { |cells| KEYS.zip(cells.fill("", cells.size...KEYS.size).first(KEYS.size)).to_h }
    end

    def self.format(rows)
      rows.map { |row| KEYS.map { |key| row[key] }.compact_blank.join(" #{SEPARATOR} ") }.join("\n")
    end
  end
end
