# frozen_string_literal: true

# Terrain du club. Remplace l'ancien enum figé (« Terrain 1 » … « Terrain 3 »).
# Un terrain qui a un historique (sessions, fermetures, tournois) n'est jamais
# supprimé : on l'archive, il disparaît des formulaires et des filtres mais
# reste affiché sur les anciennes sessions.
# Navigation unidirectionnelle : Session et TerrainClosure portent terrain_id.
class Terrain < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true }
  validates :color, inclusion: { in: Terrains::Palette::KEYS }

  # Nouveau terrain : en dernière position, avec une couleur encore libre.
  after_initialize :assign_defaults, if: :new_record?

  before_destroy :prevent_destroy_with_history

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(archived_at: nil) }

  # Accepte un id ou l'ancien nom (« Terrain 1 ») : les liens et favoris
  # antérieurs au modèle Terrain portent le nom dans `?terrain=`.
  def self.resolve(value)
    return if value.blank?

    value.to_s.match?(/\A\d+\z/) ? find_by(id: value) : find_by(name: value.to_s)
  end

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def history?
    Session.where(terrain_id: id).exists? ||
      TerrainClosure.where(terrain_id: id).exists? ||
      Tournament.where("? = ANY(terrains)", id).exists?
  end

  def palette_color
    Terrains::Palette.fetch(color)
  end

  # Libellé court du calendrier et des légendes (« T1 »).
  # Libellé court tiré du nom, stable quel que soit l'ordre :
  # « Terrain 3 » → « T3 », « Court central » → « CC », « Central » → « CEN ».
  def short_name
    words = name.to_s.split
    number = name.to_s[/\d+\z/]
    return "#{words.first[0].upcase}#{number}" if number && words.size > 1
    return words.map { |word| word[0] }.join.upcase.first(3) if words.size > 1

    name.to_s.first(3).upcase
  end

  def to_s
    name
  end

  private

  def assign_defaults
    self.position ||= (Terrain.maximum(:position) || 0) + 1
    self.color ||= Terrains::Palette.first_unused(Terrain.distinct.pluck(:color))
  end

  def prevent_destroy_with_history
    return unless history?

    errors.add(:base, "Ce terrain a un historique : archivez-le plutôt que de le supprimer")
    throw :abort
  end
end
