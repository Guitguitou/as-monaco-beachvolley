# frozen_string_literal: true

# Terrain du club. Remplace l'ancien enum figé (« Terrain 1 » … « Terrain 3 »).
# Un terrain qui a un historique (sessions, fermetures, tournois) n'est jamais
# supprimé : on l'archive, il disparaît des formulaires et des filtres mais
# reste affiché sur les anciennes sessions.
# Navigation unidirectionnelle : Session et TerrainClosure portent terrain_id.
class Terrain < ApplicationRecord
  # Couleurs de terrain définies dans le CSS (.terrain-1 … .terrain-3) et les
  # cartes ; attribuées par position, elles se répètent au-delà.
  COLOR_COUNT = 3
  validates :name, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true }

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

  def color_slot
    (position - 1) % COLOR_COUNT + 1
  end

  def to_s
    name
  end

  private

  def prevent_destroy_with_history
    return unless history?

    errors.add(:base, "Ce terrain a un historique : archivez-le plutôt que de le supprimer")
    throw :abort
  end
end
